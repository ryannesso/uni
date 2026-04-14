#include <rclcpp/rclcpp.hpp>

#include <Eigen/Geometry>

#include <abb_irb4600_ikfast/abb_irb4600_ikfast.h>

#include <geometry_msgs/msg/point.hpp>
#include <sensor_msgs/msg/joint_state.hpp>
#include <std_msgs/msg/int8.hpp>
#include <std_srvs/srv/trigger.hpp>
#include <visualization_msgs/msg/marker.hpp>

#include "cv8_traj/manipulator.hpp"

#include <atomic>
#include <chrono>
#include <cmath>
#include <fstream>
#include <limits>
#include <mutex>
#include <string>
#include <thread>

namespace {

constexpr std::size_t kDof = 6;

const std::array<std::string, kDof> & jointNames()
{
  static const std::array<std::string, kDof> names = {
    "joint_1", "joint_2", "joint_3", "joint_4", "joint_5", "joint_6"};
  return names;
}

double angleDiff(double a, double b)
{
  return std::atan2(std::sin(a - b), std::cos(a - b));
}

double jointDistanceSq(const ikfast_abb::JointValues & a, const std::array<double, kDof> & b)
{
  double sum = 0.0;
  for (std::size_t i = 0; i < kDof; ++i) {
    const double d = angleDiff(a[i], b[i]);
    sum += d * d;
  }
  return sum;
}

double jointDistanceSqArrays(const std::array<double, kDof> & a, const std::array<double, kDof> & b)
{
  double sum = 0.0;
  for (std::size_t i = 0; i < kDof; ++i) {
    const double d = angleDiff(a[i], b[i]);
    sum += d * d;
  }
  return sum;
}

visualization_msgs::msg::Marker makeLineStrip(
  const std::string & frame,
  const std::string & ns,
  int id,
  float r,
  float g,
  float b)
{
  // создает line strip маркер для визуализации пройденного пути
  visualization_msgs::msg::Marker m;
  m.header.frame_id = frame;
  m.ns = ns;
  m.id = id;
  m.type = visualization_msgs::msg::Marker::LINE_STRIP;
  m.action = visualization_msgs::msg::Marker::ADD;
  m.pose.orientation.w = 1.0;
  m.scale.x = 0.005;
  m.color.r = r;
  m.color.g = g;
  m.color.b = b;
  m.color.a = 1.0f;
  return m;
}

}  // namespace

class ManipulatorNode : public rclcpp::Node
{
public:
  enum State : int8_t
  {
    IDLE = 0,
    PTP = 1,
    APPROACHING = 2,
    MACHINING = 3,
    RETRACTING = 4,
    TRANSITION = 5,
    ERROR = 100
  };

  explicit ManipulatorNode(const rclcpp::NodeOptions & options)
  : Node("manipulator_node", options), manip_(kDof)
  {
    declareParams();

    joint_pub_ = this->create_publisher<sensor_msgs::msg::JointState>("/joint_states", 10);
    joint_sub_ = this->create_subscription<sensor_msgs::msg::JointState>(
      "/joint_states",
      10,
      [this](const sensor_msgs::msg::JointState::ConstSharedPtr msg) {
        if (msg->name.size() != msg->position.size()) {
          return;
        }

        const auto & names = jointNames();
        std::array<double, kDof> updated;
        {
          std::lock_guard<std::mutex> lock(jointsMtx_);
          updated = last_q_;
        }

        bool any = false;
        for (std::size_t i = 0; i < kDof; ++i) {
          for (std::size_t j = 0; j < msg->name.size(); ++j) {
            if (msg->name[j] == names[i]) {
              updated[i] = msg->position[j];
              any = true;
              break;
            }
          }
        }

        if (any) {
          std::lock_guard<std::mutex> lock(jointsMtx_);
          last_q_ = updated;
          have_last_q_ = true;
        }
      });
    state_pub_ = this->create_publisher<std_msgs::msg::Int8>("manipulator/state", 10);

    auto marker_qos = rclcpp::QoS(rclcpp::KeepLast(1)).transient_local().reliable();
    path_pub_ = this->create_publisher<visualization_msgs::msg::Marker>("manipulator/path", marker_qos);

    srv_ = this->create_service<std_srvs::srv::Trigger>(
      "execute_machining",
      std::bind(&ManipulatorNode::executeCb, this, std::placeholders::_1, std::placeholders::_2));

    setState(IDLE);

    RCLCPP_INFO(this->get_logger(), "ManipulatorNode ready. Call /execute_machining (std_srvs/Trigger).");
  }

  ~ManipulatorNode() override
  {
    stopRequested_.store(true);
    if (worker_.joinable()) {
      worker_.join();
    }
  }

private:
  cv8_traj::Manipulator manip_;

  rclcpp::Publisher<sensor_msgs::msg::JointState>::SharedPtr joint_pub_;
  rclcpp::Subscription<sensor_msgs::msg::JointState>::SharedPtr joint_sub_;
  rclcpp::Publisher<std_msgs::msg::Int8>::SharedPtr state_pub_;
  rclcpp::Publisher<visualization_msgs::msg::Marker>::SharedPtr path_pub_;
  rclcpp::Service<std_srvs::srv::Trigger>::SharedPtr srv_;

  std::thread worker_;
  std::atomic<bool> running_{false};
  std::atomic<bool> stopRequested_{false};

  std::mutex stateMtx_;
  State state_{IDLE};

  std::mutex jointsMtx_;
  std::array<double, kDof> last_q_{};
  bool have_last_q_{false};

  // параметры
  std::array<double, kDof> home_{};
  std::array<double, kDof> t1_{};
  std::array<double, kDof> t2_{};
  std::array<double, kDof> t3_{};
  std::array<double, kDof> t4_{};
  std::array<double, kDof> tvia_{};

  bool has_t2_{false};
  bool has_t4_{false};

  Eigen::Vector3d edge1_{0.0, 0.20, 0.0};
  Eigen::Vector3d edge2_{0.0, 0.20, 0.0};
  bool edge_in_tool_frame_{true};

  double dt_{0.01};
  double ptp_time_{4.0};
  double trans_time1_{3.0};
  double trans_time2_{3.0};

  double approach_offset_{-0.15};
  double v_approach_{0.08};
  double v_machining_{0.03};

  int log_joint_index_{1};
  std::array<int, 3> log_joint_indices_{{0, 1, 2}};
  std::string log_path_{"/tmp/cv8_traj_joint_log.csv"};
  std::string log_tool_path_{"/tmp/cv8_traj_tool_log.csv"};

  void declareParams()
  {
    // объявляет все параметры, затем сразу читает их в локальные поля
    this->declare_parameter<std::vector<double>>("home", std::vector<double>(kDof, 0.0));
    this->declare_parameter<std::vector<double>>("t1", std::vector<double>(kDof, 0.0));
    this->declare_parameter<std::vector<double>>("t2", std::vector<double>());
    this->declare_parameter<std::vector<double>>("t3", std::vector<double>(kDof, 0.0));
    this->declare_parameter<std::vector<double>>("t4", std::vector<double>());
    this->declare_parameter<std::vector<double>>("tvia", std::vector<double>(kDof, 0.0));

    this->declare_parameter<std::vector<double>>("edge1", std::vector<double>({0.0, 0.20, 0.0}));
    this->declare_parameter<std::vector<double>>("edge2", std::vector<double>({0.0, 0.20, 0.0}));
    this->declare_parameter<bool>("edge_in_tool_frame", edge_in_tool_frame_);

    this->declare_parameter<double>("dt", dt_);
    this->declare_parameter<double>("ptp_time", ptp_time_);
    this->declare_parameter<double>("transition_time_a_via", trans_time1_);
    this->declare_parameter<double>("transition_time_via_b", trans_time2_);

    this->declare_parameter<double>("approach_offset", approach_offset_);
    this->declare_parameter<double>("v_approach", v_approach_);
    this->declare_parameter<double>("v_machining", v_machining_);

    this->declare_parameter<int>("log_joint_index", log_joint_index_);
    this->declare_parameter<std::vector<int64_t>>("log_joint_indices", std::vector<int64_t>({0, 1, 2}));
    this->declare_parameter<std::string>("log_path", log_path_);
    this->declare_parameter<std::string>("log_tool_path", log_tool_path_);

    loadParams();
  }

  void loadParams()
  {
    // load6 читает до 6 значений с безопасным заполнением отсутствующих элементов
    auto load6 = [this](const std::string & name, std::array<double, kDof> & out) {
      auto v = this->get_parameter(name).as_double_array();
      for (std::size_t i = 0; i < kDof; ++i) {
        out[i] = (i < v.size()) ? v[i] : 0.0;
      }
    };

    // loadMaybe6 позволяет отличить "параметр не задан" от валидной точки из 6 углов
    auto loadMaybe6 = [this](const std::string & name, std::array<double, kDof> & out) -> bool {
      auto v = this->get_parameter(name).as_double_array();
      if (v.size() < kDof) {
        return false;
      }
      for (std::size_t i = 0; i < kDof; ++i) {
        out[i] = v[i];
      }
      return true;
    };

    load6("home", home_);
    load6("t1", t1_);
    has_t2_ = loadMaybe6("t2", t2_);
    load6("t3", t3_);
    has_t4_ = loadMaybe6("t4", t4_);
    load6("tvia", tvia_);

    auto e1 = this->get_parameter("edge1").as_double_array();
    auto e2 = this->get_parameter("edge2").as_double_array();
    if (e1.size() >= 3) {
      edge1_ = Eigen::Vector3d(e1[0], e1[1], e1[2]);
    }
    if (e2.size() >= 3) {
      edge2_ = Eigen::Vector3d(e2[0], e2[1], e2[2]);
    }
    edge_in_tool_frame_ = this->get_parameter("edge_in_tool_frame").as_bool();

    dt_ = this->get_parameter("dt").as_double();
    ptp_time_ = this->get_parameter("ptp_time").as_double();
    trans_time1_ = this->get_parameter("transition_time_a_via").as_double();
    trans_time2_ = this->get_parameter("transition_time_via_b").as_double();

    approach_offset_ = this->get_parameter("approach_offset").as_double();
    v_approach_ = this->get_parameter("v_approach").as_double();
    v_machining_ = this->get_parameter("v_machining").as_double();

    log_joint_index_ = this->get_parameter("log_joint_index").as_int();
    const auto joint_indices = this->get_parameter("log_joint_indices").as_integer_array();
    log_path_ = this->get_parameter("log_path").as_string();
    log_tool_path_ = this->get_parameter("log_tool_path").as_string();

    log_joint_index_ = std::max(0, std::min(static_cast<int>(kDof - 1), log_joint_index_));

    auto clamp_joint = [](int j) {
      return std::max(0, std::min(static_cast<int>(kDof - 1), j));
    };

    if (joint_indices.size() >= 3) {
      for (std::size_t i = 0; i < 3; ++i) {
        log_joint_indices_[i] = clamp_joint(static_cast<int>(joint_indices[i]));
      }
    } else {
      // если список не задан, логирует три соседних сустава от базового индекса
      log_joint_indices_[0] = clamp_joint(log_joint_index_);
      log_joint_indices_[1] = clamp_joint(log_joint_index_ + 1);
      log_joint_indices_[2] = clamp_joint(log_joint_index_ + 2);
    }
  }

  void setState(State s)
  {
    std::lock_guard<std::mutex> lock(stateMtx_);
    auto stateName = [](State st) -> const char * {
      switch (st) {
        case IDLE:
          return "IDLE";
        case PTP:
          return "PTP";
        case APPROACHING:
          return "APPROACHING";
        case MACHINING:
          return "MACHINING";
        case RETRACTING:
          return "RETRACTING";
        case TRANSITION:
          return "TRANSITION";
        case ERROR:
          return "ERROR";
        default:
          return "UNKNOWN";
      }
    };

    // публикует состояние в топик и печатает переход в консоль
    const State prev = state_;
    state_ = s;
    std_msgs::msg::Int8 msg;
    msg.data = static_cast<int8_t>(s);
    state_pub_->publish(msg);

    if (prev != s) {
      RCLCPP_INFO(
        this->get_logger(),
        "State: %s (%d) -> %s (%d)",
        stateName(prev), static_cast<int>(prev), stateName(s), static_cast<int>(s));
    }
  }

  void publishJoints(const std::array<double, kDof> & q, const std::array<double, kDof> & qd)
  {
    sensor_msgs::msg::JointState js;
    js.header.stamp = this->now();
    const auto & names = jointNames();
    js.name.assign(names.begin(), names.end());
    js.position.assign(q.begin(), q.end());
    js.velocity.assign(qd.begin(), qd.end());
    joint_pub_->publish(js);
  }

  bool solveNearestIk(
    const Eigen::Affine3d & pose,
    const std::array<double, kDof> & q_prev,
    std::array<double, kDof> & q_out) const
  {
    // выбирает из всех ik решений то, которое ближе к предыдущей конфигурации
    const ikfast_abb::Solutions sols = ikfast_abb::computeIK(pose);
    if (sols.empty()) {
      return false;
    }

    std::size_t best_i = 0;
    double best_d = jointDistanceSq(sols[0], q_prev);
    for (std::size_t i = 1; i < sols.size(); ++i) {
      const double d = jointDistanceSq(sols[i], q_prev);
      if (d < best_d) {
        best_d = d;
        best_i = i;
      }
    }

    for (std::size_t i = 0; i < kDof; ++i) {
      q_out[i] = sols[best_i][i];
    }
    return true;
  }

  static double linDurationFromSpeed(const Eigen::Vector3d & p0, const Eigen::Vector3d & p1, double v)
  {
    // оценивает длительность lin сегмента по длине и желаемой скорости tcp
    const double dist = (p1 - p0).norm();
    if (!(v > 0.0)) {
      return 1.0;
    }
    // для quintic time-scaling пиковая скорость примерно 1.875 * dist / T
    return std::max(0.2, 1.875 * dist / v);
  }

  void executeCb(
    const std::shared_ptr<std_srvs::srv::Trigger::Request>,
    std::shared_ptr<std_srvs::srv::Trigger::Response> res)
  {
    // стартует выполнение в отдельном потоке, чтобы service отвечал сразу
    if (worker_.joinable()) {
      worker_.join();
    }

    if (running_.exchange(true)) {
      res->success = false;
      res->message = "Already running";
      return;
    }

    stopRequested_.store(false);
    loadParams();

    worker_ = std::thread([this]() {
      try {
        runSequence();
        setState(IDLE);
      } catch (const std::exception & e) {
        RCLCPP_ERROR(this->get_logger(), "Execution error: %s", e.what());
        setState(ERROR);
      }
      running_.store(false);
    });

    res->success = true;
    res->message = "Started";
  }

  void runSequence()
  {
    // формирует и выполняет полную технологическую последовательность движений
    int marker_id = 0;

    double t_global = 0.0;

    auto joint_log = std::ofstream(log_path_, std::ios::out | std::ios::trunc);
    joint_log << "t";
    for (const int j : log_joint_indices_) {
      const int j_human = j + 1;
      joint_log << ",q_j" << j_human << ",qd_j" << j_human << ",qdd_j" << j_human;
    }
    joint_log << "\n";

    auto tool_log = std::ofstream(log_tool_path_, std::ios::out | std::ios::trunc);
    tool_log << "t,x,y,z,motion\n";

    std::array<double, kDof> q;
    {
      std::lock_guard<std::mutex> lock(jointsMtx_);
      q = have_last_q_ ? last_q_ : home_;
    }
    auto qd = std::array<double, kDof>{};

    publishJoints(q, qd);

    // при необходимости сначала мягко возвращает робота в home
    if (jointDistanceSqArrays(q, home_) > 1e-6) {
      setState(PTP);
      auto m = makeLineStrip("base_link", "ptp", marker_id++, 0.1f, 0.4f, 1.0f);
      executePtp(q, home_, ptp_time_, m, joint_log, tool_log, "ptp", t_global);
      path_pub_->publish(m);
    }

    // вычисляет декартовы позы для t1, t3 и конечных точек ребер
    ikfast_abb::JointValues q1j, q3j;
    for (std::size_t i = 0; i < kDof; ++i) {
      q1j[i] = t1_[i];
      q3j[i] = t3_[i];
    }

    const Eigen::Affine3d T1 = ikfast_abb::computeFk(q1j);
    const Eigen::Affine3d T3 = ikfast_abb::computeFk(q3j);

    Eigen::Affine3d T2 = T1;
    if (has_t2_) {
      ikfast_abb::JointValues q2j;
      for (std::size_t i = 0; i < kDof; ++i) {
        q2j[i] = t2_[i];
      }
      const Eigen::Affine3d fk2 = ikfast_abb::computeFk(q2j);
      T2.translation() = fk2.translation();
    } else {
      const Eigen::Vector3d edge1_world = edge_in_tool_frame_ ? (T1.rotation() * edge1_) : edge1_;
      T2.translation() = T1.translation() + edge1_world;
    }

    Eigen::Affine3d T4 = T3;
    if (has_t4_) {
      ikfast_abb::JointValues q4j;
      for (std::size_t i = 0; i < kDof; ++i) {
        q4j[i] = t4_[i];
      }
      const Eigen::Affine3d fk4 = ikfast_abb::computeFk(q4j);
      T4.translation() = fk4.translation();
    } else {
      const Eigen::Vector3d edge2_world = edge_in_tool_frame_ ? (T3.rotation() * edge2_) : edge2_;
      T4.translation() = T3.translation() + edge2_world;
    }

    auto offsetAlongWorldZ = [this](const Eigen::Affine3d & pose) {
      Eigen::Affine3d out = pose;
      out.translation().z() += std::abs(approach_offset_);
      return out;
    };

    const Eigen::Affine3d A1 = offsetAlongWorldZ(T1);
    const Eigen::Affine3d R2 = offsetAlongWorldZ(T2);
    const Eigen::Affine3d A3 = offsetAlongWorldZ(T3);
    const Eigen::Affine3d R4 = offsetAlongWorldZ(T4);

    // заранее считает ik для точек подхода и отхода
    std::array<double, kDof> q_A1, q_R2, q_A3, q_R4;

    if (!solveNearestIk(A1, t1_, q_A1)) {
      throw std::runtime_error("No IK for Approach(T1)");
    }
    if (!solveNearestIk(R2, t1_, q_R2)) {
      throw std::runtime_error("No IK for Retract(T2)");
    }
    if (!solveNearestIk(A3, t3_, q_A3)) {
      throw std::runtime_error("No IK for Approach(T3)");
    }
    if (!solveNearestIk(R4, t3_, q_R4)) {
      throw std::runtime_error("No IK for Retract(T4)");
    }

    // 1) home -> approach(t1) через ptp
    {
      setState(PTP);
      auto m = makeLineStrip("base_link", "ptp", marker_id++, 0.1f, 0.4f, 1.0f);
      executePtp(q, q_A1, ptp_time_, m, joint_log, tool_log, "ptp", t_global);
      path_pub_->publish(m);
    }

    // 2) lin prisun: approach(t1) -> t1
    {
      setState(APPROACHING);
      auto m = makeLineStrip("base_link", "approach", marker_id++, 1.0f, 0.1f, 0.1f);
      executeLin(q, A1, T1, v_approach_, m, joint_log, tool_log, "approach", t_global);
      path_pub_->publish(m);
    }

    // 3) lin obrabotka: t1 -> t2
    {
      setState(MACHINING);
      auto m = makeLineStrip("base_link", "machining", marker_id++, 0.1f, 1.0f, 0.1f);
      executeLin(q, T1, T2, v_machining_, m, joint_log, tool_log, "machining", t_global);
      path_pub_->publish(m);
    }

    // 4) lin odsun: t2 -> retract(t2)
    {
      setState(RETRACTING);
      auto m = makeLineStrip("base_link", "retract", marker_id++, 1.0f, 0.1f, 0.1f);
      executeLin(q, T2, R2, v_approach_, m, joint_log, tool_log, "retract", t_global);
      path_pub_->publish(m);
    }

    // 5) transition: retract(t2) -> tvia -> approach(t3)
    {
      setState(TRANSITION);
      auto m = makeLineStrip("base_link", "transition", marker_id++, 0.1f, 0.4f, 1.0f);
      executePtpVia(q, tvia_, q_A3, trans_time1_, trans_time2_, m, joint_log, tool_log, "transition", t_global);
      path_pub_->publish(m);
    }

    // 6) lin prisun: approach(t3) -> t3
    {
      setState(APPROACHING);
      auto m = makeLineStrip("base_link", "approach", marker_id++, 1.0f, 0.1f, 0.1f);
      executeLin(q, A3, T3, v_approach_, m, joint_log, tool_log, "approach", t_global);
      path_pub_->publish(m);
    }

    // 7) lin obrabotka: t3 -> t4
    {
      setState(MACHINING);
      auto m = makeLineStrip("base_link", "machining", marker_id++, 0.1f, 1.0f, 0.1f);
      executeLin(q, T3, T4, v_machining_, m, joint_log, tool_log, "machining", t_global);
      path_pub_->publish(m);
    }

    // 8) lin odsun: t4 -> retract(t4)
    {
      setState(RETRACTING);
      auto m = makeLineStrip("base_link", "retract", marker_id++, 1.0f, 0.1f, 0.1f);
      executeLin(q, T4, R4, v_approach_, m, joint_log, tool_log, "retract", t_global);
      path_pub_->publish(m);
    }

    // 9) retract(t4) -> home через ptp
    {
      setState(PTP);
      auto m = makeLineStrip("base_link", "ptp", marker_id++, 0.1f, 0.4f, 1.0f);
      executePtp(q, home_, ptp_time_, m, joint_log, tool_log, "ptp", t_global);
      path_pub_->publish(m);
    }
  }

  void executePtp(
    std::array<double, kDof> & q_curr,
    const std::array<double, kDof> & q_goal,
    double duration_s,
    visualization_msgs::msg::Marker & path,
    std::ofstream & joint_log,
    std::ofstream & tool_log,
    const char * motion,
    double & t_global)
  {
    // исполняет готовую суставную траекторию и пишет данные в логи
    Eigen::VectorXd q0(kDof), q1(kDof);
    for (std::size_t i = 0; i < kDof; ++i) {
      q0(i) = q_curr[i];
      q1(i) = q_goal[i];
    }

    const auto traj = manip_.samplePtpQuintic(q0, q1, duration_s, dt_);

    for (const auto & pt : traj) {
      if (stopRequested_.load()) {
        throw std::runtime_error("Stop requested");
      }

      std::array<double, kDof> qd{};
      for (std::size_t i = 0; i < kDof; ++i) {
        q_curr[i] = pt.q(i);
        qd[i] = pt.qd(i);
      }
      publishJoints(q_curr, qd);

      appendToolPoint(path, q_curr);
      logJointPoint(joint_log, t_global + pt.t, pt.q, pt.qd, pt.qdd);
      logToolPoint(tool_log, t_global + pt.t, q_curr, motion);

      rclcpp::sleep_for(std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::duration<double>(dt_)));
    }

    t_global += duration_s;
  }

  void executePtpVia(
    std::array<double, kDof> & q_curr,
    const std::array<double, kDof> & q_via,
    const std::array<double, kDof> & q_goal,
    double dur1,
    double dur2,
    visualization_msgs::msg::Marker & path,
    std::ofstream & joint_log,
    std::ofstream & tool_log,
    const char * motion,
    double & t_global)
  {
    // исполняет переход через via с непрерывным профилем
    Eigen::VectorXd qa(kDof), qc(kDof), qb(kDof);
    for (std::size_t i = 0; i < kDof; ++i) {
      qa(i) = q_curr[i];
      qc(i) = q_via[i];
      qb(i) = q_goal[i];
    }

    const auto traj = manip_.samplePtpVia(qa, qc, qb, dur1, dur2, dt_);

    for (const auto & pt : traj) {
      if (stopRequested_.load()) {
        throw std::runtime_error("Stop requested");
      }

      std::array<double, kDof> qd{};
      for (std::size_t i = 0; i < kDof; ++i) {
        q_curr[i] = pt.q(i);
        qd[i] = pt.qd(i);
      }
      publishJoints(q_curr, qd);

      appendToolPoint(path, q_curr);
      logJointPoint(joint_log, t_global + pt.t, pt.q, pt.qd, pt.qdd);
      logToolPoint(tool_log, t_global + pt.t, q_curr, motion);

      rclcpp::sleep_for(std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::duration<double>(dt_)));
    }

    t_global += (dur1 + dur2);
  }

  void executeLin(
    std::array<double, kDof> & q_curr,
    const Eigen::Affine3d & start,
    const Eigen::Affine3d & goal,
    double speed,
    visualization_msgs::msg::Marker & path,
    std::ofstream & joint_log,
    std::ofstream & tool_log,
    const char * motion,
    double & t_global)
  {
    // строит lin позы, в каждой позе решает ik и обновляет состояние робота
    const double T = linDurationFromSpeed(start.translation(), goal.translation(), speed);
    const auto poses = manip_.sampleLinPoses(start, goal, T, dt_);

    // численно оценивает qd и qdd для последующего анализа графиков
    std::array<double, kDof> q_prev = q_curr;
    std::array<double, kDof> qd_prev{};
    Eigen::VectorXd qv(kDof), qdv(kDof), qddv(kDof);

    for (std::size_t k = 0; k < poses.size(); ++k) {
      if (stopRequested_.load()) {
        throw std::runtime_error("Stop requested");
      }

      std::array<double, kDof> q_next;
      if (!solveNearestIk(poses[k], q_curr, q_next)) {
        throw std::runtime_error("LIN: IK failed at some pose");
      }

      q_curr = q_next;

      std::array<double, kDof> qd{};
      std::array<double, kDof> qdd{};

      if (k == 0) {
        // старт сегмента
        qd.fill(0.0);
        qdd.fill(0.0);
      } else {
        for (std::size_t i = 0; i < kDof; ++i) {
          qd[i] = angleDiff(q_curr[i], q_prev[i]) / dt_;
          qdd[i] = (qd[i] - qd_prev[i]) / dt_;
        }
      }

      publishJoints(q_curr, qd);

      appendToolPoint(path, q_curr);

      for (std::size_t i = 0; i < kDof; ++i) {
        qv(i) = q_curr[i];
        qdv(i) = qd[i];
        qddv(i) = qdd[i];
      }
      const double t_local = std::min(T, static_cast<double>(k) * dt_);
      logJointPoint(joint_log, t_global + t_local, qv, qdv, qddv);
      logToolPoint(tool_log, t_global + t_local, q_curr, motion);

      q_prev = q_curr;
      qd_prev = qd;

      rclcpp::sleep_for(std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::duration<double>(dt_)));
    }

    t_global += T;
  }

  void appendToolPoint(visualization_msgs::msg::Marker & path, const std::array<double, kDof> & q)
  {
    // добавляет текущую точку tcp в marker траектории
    ikfast_abb::JointValues jq;
    for (std::size_t i = 0; i < kDof; ++i) {
      jq[i] = q[i];
    }
    const Eigen::Affine3d fk = ikfast_abb::computeFk(jq);

    geometry_msgs::msg::Point p;
    p.x = fk.translation().x();
    p.y = fk.translation().y();
    p.z = fk.translation().z();

    path.header.stamp = this->now();
    path.points.push_back(p);
  }

  void logJointPoint(
    std::ofstream & log,
    double t,
    const Eigen::VectorXd & q,
    const Eigen::VectorXd & qd,
    const Eigen::VectorXd & qdd)
  {
    // пишет одну строку лога сразу для трех выбранных суставов
    log << t;
    for (const int j : log_joint_indices_) {
      if (q.size() <= j || qd.size() <= j || qdd.size() <= j) {
        log << ",0,0,0";
      } else {
        log << "," << q(j) << "," << qd(j) << "," << qdd(j);
      }
    }
    log << "\n";
  }

  void logToolPoint(
    std::ofstream & log,
    double t,
    const std::array<double, kDof> & q,
    const char * motion)
  {
    // пишет одну строку лога tcp с типом движения
    ikfast_abb::JointValues jq;
    for (std::size_t i = 0; i < kDof; ++i) {
      jq[i] = q[i];
    }
    const Eigen::Affine3d fk = ikfast_abb::computeFk(jq);
    log << t << "," << fk.translation().x() << "," << fk.translation().y() << "," << fk.translation().z() << "," << motion << "\n";
  }
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::NodeOptions options;
  options.allow_undeclared_parameters(true);
  options.automatically_declare_parameters_from_overrides(false);
  rclcpp::spin(std::make_shared<ManipulatorNode>(options));
  rclcpp::shutdown();
  return 0;
}
