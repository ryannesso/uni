#include <rclcpp/rclcpp.hpp>

#include <Eigen/Geometry>

#include <interactive_markers/interactive_marker_server.hpp>
#include <visualization_msgs/msg/interactive_marker.hpp>
#include <visualization_msgs/msg/interactive_marker_control.hpp>
#include <visualization_msgs/msg/interactive_marker_feedback.hpp>
#include <visualization_msgs/msg/marker.hpp>

#include <geometry_msgs/msg/pose.hpp>
#include <sensor_msgs/msg/joint_state.hpp>
#include <std_msgs/msg/int8.hpp>

#include "abb_irb4600_ikfast/abb_irb4600_ikfast.h"

namespace {

constexpr std::size_t kDof = 6;  // размерность робота: 6 суставов

// возвращает имена суставов для корректного сопоставления joint_states
const std::array<std::string, kDof> & jointNames()
{
  static const std::array<std::string, kDof> names = {
    "joint_1", "joint_2", "joint_3", "joint_4", "joint_5", "joint_6"};
  return names;
}

// переводит pose из ros сообщения в affine3d для вызова ik
Eigen::Affine3d poseMsgToEigen(const geometry_msgs::msg::Pose & pose)
{
  Eigen::Quaterniond q(pose.orientation.w, pose.orientation.x, pose.orientation.y, pose.orientation.z);
  q.normalize();
  Eigen::Affine3d T = Eigen::Affine3d::Identity();
  T.linear() = q.toRotationMatrix();
  T.translation() = Eigen::Vector3d(pose.position.x, pose.position.y, pose.position.z);
  return T;
}

// считает разницу углов с учетом периодичности, чтобы избежать скачков на границе +/-pi
double angleDiff(double a, double b)
{
  return std::atan2(std::sin(a - b), std::cos(a - b));
}

// возвращает квадратичную дистанцию между конфигурациями для выбора ближайшего ik решения
double jointDistanceSq(const ikfast_abb::JointValues & a, const std::array<double, kDof> & b)
{
  double sum = 0.0;
  for (std::size_t i = 0; i < kDof; ++i) {
    const double d = angleDiff(a[i], b[i]);
    sum += d * d;
  }
  return sum;
}

}  // namespace

class PoseTeacher : public rclcpp::Node
{
public:
  PoseTeacher() : Node("pose_teacher")
  {
    this->declare_parameter<std::vector<double>>("initial_joints", std::vector<double>(kDof, 0.0));
    this->declare_parameter<double>("publish_rate_hz", 0.0);
    this->declare_parameter<std::string>("state_topic", std::string("/manipulator/state"));

    auto init = this->get_parameter("initial_joints").as_double_array();
    for (std::size_t i = 0; i < kDof; ++i) {
      current_joints_[i] = (i < init.size()) ? init[i] : 0.0;
    }

    joint_pub_ = this->create_publisher<sensor_msgs::msg::JointState>("/joint_states", 10);

    joint_state_sub_ = this->create_subscription<sensor_msgs::msg::JointState>(
      "/joint_states", 10, std::bind(&PoseTeacher::jointStateCb, this, std::placeholders::_1));

    const auto state_topic = this->get_parameter("state_topic").as_string();
    state_sub_ = this->create_subscription<std_msgs::msg::Int8>(
      state_topic, 10, std::bind(&PoseTeacher::stateCb, this, std::placeholders::_1));

    server_ = std::make_shared<interactive_markers::InteractiveMarkerServer>(
      "pose_teacher/interactive_marker", this);

    createMarkerFromCurrentFk();

    // публикует один стартовый joint state, чтобы модель сразу была видна в rviz
    publishJoints();

    const double publish_rate_hz = this->get_parameter("publish_rate_hz").as_double();
    if (publish_rate_hz > 0.0) {
      const auto period = std::chrono::duration_cast<std::chrono::nanoseconds>(
        std::chrono::duration<double>(1.0 / publish_rate_hz));
      publish_timer_ = this->create_wall_timer(period, [this]() {
        if (allow_joint_publishing_.load()) {
          publishJoints();
        }
      });
    }

    RCLCPP_INFO(this->get_logger(), "PoseTeacher ready. Drag the 6-DOF marker in RViz.");
  }

private:
  rclcpp::Publisher<sensor_msgs::msg::JointState>::SharedPtr joint_pub_;
  rclcpp::Subscription<sensor_msgs::msg::JointState>::SharedPtr joint_state_sub_;
  rclcpp::Subscription<std_msgs::msg::Int8>::SharedPtr state_sub_;
  rclcpp::TimerBase::SharedPtr publish_timer_;

  std::shared_ptr<interactive_markers::InteractiveMarkerServer> server_;
  std::array<double, kDof> current_joints_{};
  std::mutex joints_mtx_;
  std::atomic<bool> allow_joint_publishing_{true};

  // публикует текущую конфигурацию в /joint_states
  void publishJoints()
  {
    sensor_msgs::msg::JointState js;
    js.header.stamp = this->now();
    const auto & names = jointNames();
    js.name.assign(names.begin(), names.end());

    {
      std::lock_guard<std::mutex> lock(joints_mtx_);
      js.position.assign(current_joints_.begin(), current_joints_.end());
    }

    joint_pub_->publish(js);
  }

  // синхронизирует локальное состояние с входящим joint_states
  void jointStateCb(const sensor_msgs::msg::JointState::ConstSharedPtr & msg)
  {
    if (msg->name.size() != msg->position.size()) {
      return;
    }

    const auto & names = jointNames();
    std::array<double, kDof> updated;

    {
      std::lock_guard<std::mutex> lock(joints_mtx_);
      updated = current_joints_;
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
      std::lock_guard<std::mutex> lock(joints_mtx_);
      current_joints_ = updated;
    }
  }

  // отключает публикацию из teacher, когда манипулятор выполняет автоматическую последовательность
  void stateCb(const std_msgs::msg::Int8::ConstSharedPtr & msg)
  {
    // публикует joint_states только когда манипулятор в состоянии idle
    allow_joint_publishing_.store(msg->data == 0);
  }

  // создает 6 dof маркер в текущей fk позе tcp
  void createMarkerFromCurrentFk()
  {
    ikfast_abb::JointValues q;
    for (std::size_t i = 0; i < kDof; ++i) {
      q[i] = current_joints_[i];
    }
    const Eigen::Affine3d fk = ikfast_abb::computeFk(q);

    visualization_msgs::msg::InteractiveMarker int_marker;
    int_marker.header.frame_id = "base_link";
    int_marker.name = "tcp_target";
    int_marker.description = "TCP target (drag)";
    int_marker.scale = 0.35;

    Eigen::Quaterniond quat(fk.rotation());
    quat.normalize();
    int_marker.pose.position.x = fk.translation().x();
    int_marker.pose.position.y = fk.translation().y();
    int_marker.pose.position.z = fk.translation().z();
    int_marker.pose.orientation.w = quat.w();
    int_marker.pose.orientation.x = quat.x();
    int_marker.pose.orientation.y = quat.y();
    int_marker.pose.orientation.z = quat.z();

    // добавляет видимую сферу в точке tcp
    visualization_msgs::msg::Marker sphere;
    sphere.type = visualization_msgs::msg::Marker::SPHERE;
    sphere.scale.x = 0.05;
    sphere.scale.y = 0.05;
    sphere.scale.z = 0.05;
    sphere.color.r = 0.9f;
    sphere.color.g = 0.9f;
    sphere.color.b = 0.1f;
    sphere.color.a = 1.0f;

    visualization_msgs::msg::InteractiveMarkerControl vis;
    vis.always_visible = true;
    vis.markers.push_back(sphere);
    int_marker.controls.push_back(vis);

    add6DofControls(int_marker);

    server_->insert(int_marker, std::bind(&PoseTeacher::feedbackCb, this, std::placeholders::_1));
    // фиксирует изменения маркера на сервере interactive markers
    server_->applyChanges();
  }

  // добавляет оси перемещения и вращения для 6 dof управления
  static void add6DofControls(visualization_msgs::msg::InteractiveMarker & m)
  {
    auto add_ctrl = [&m](
      const std::string & name,
      double qw, double qx, double qy, double qz,
      uint8_t interaction)
    {
      visualization_msgs::msg::InteractiveMarkerControl c;
      c.name = name;
      c.orientation.w = qw;
      c.orientation.x = qx;
      c.orientation.y = qy;
      c.orientation.z = qz;
      c.orientation_mode = visualization_msgs::msg::InteractiveMarkerControl::FIXED;
      c.interaction_mode = interaction;
      m.controls.push_back(c);
    };

    // ось действия каждого control это его +x, кватернионы поворачивают ее в нужное направление
    const double s = std::sqrt(0.5);  // sin/cos(pi/4)

    // ось +x
    add_ctrl("move_x", 1.0, 0.0, 0.0, 0.0, visualization_msgs::msg::InteractiveMarkerControl::MOVE_AXIS);
    // ось +y
    add_ctrl("move_y", s, 0.0, 0.0, s, visualization_msgs::msg::InteractiveMarkerControl::MOVE_AXIS);
    // ось +z
    add_ctrl("move_z", s, 0.0, -s, 0.0, visualization_msgs::msg::InteractiveMarkerControl::MOVE_AXIS);

    add_ctrl("rot_x", 1.0, 0.0, 0.0, 0.0, visualization_msgs::msg::InteractiveMarkerControl::ROTATE_AXIS);
    add_ctrl("rot_y", s, 0.0, 0.0, s, visualization_msgs::msg::InteractiveMarkerControl::ROTATE_AXIS);
    add_ctrl("rot_z", s, 0.0, -s, 0.0, visualization_msgs::msg::InteractiveMarkerControl::ROTATE_AXIS);
  }

  // обрабатывает перемещение маркера: считает ik, выбирает ближайшее решение и публикует суставы
  void feedbackCb(const visualization_msgs::msg::InteractiveMarkerFeedback::ConstSharedPtr & feedback)
  {
    if (!allow_joint_publishing_.load()) {
      return;
    }

    if (feedback->event_type != visualization_msgs::msg::InteractiveMarkerFeedback::POSE_UPDATE &&
        feedback->event_type != visualization_msgs::msg::InteractiveMarkerFeedback::MOUSE_UP)
    {
      return;
    }

    const Eigen::Affine3d target = poseMsgToEigen(feedback->pose);
    const ikfast_abb::Solutions sols = ikfast_abb::computeIK(target);
    if (sols.empty()) {
      if (feedback->event_type == visualization_msgs::msg::InteractiveMarkerFeedback::MOUSE_UP) {
        RCLCPP_WARN(this->get_logger(), "No IK solution for released pose.");
      }
      return;
    }

    // выбирает решение, ближайшее к предыдущей конфигурации
    std::size_t best_i = 0;
    std::array<double, kDof> q_prev;
    {
      std::lock_guard<std::mutex> lock(joints_mtx_);
      q_prev = current_joints_;
    }

    double best_d = jointDistanceSq(sols[0], q_prev);
    for (std::size_t i = 1; i < sols.size(); ++i) {
      const double d = jointDistanceSq(sols[i], q_prev);
      if (d < best_d) {
        best_d = d;
        best_i = i;
      }
    }

    {
      std::lock_guard<std::mutex> lock(joints_mtx_);
      for (std::size_t i = 0; i < kDof; ++i) {
        current_joints_[i] = sols[best_i][i];
      }
    }

    publishJoints();

    if (feedback->event_type == visualization_msgs::msg::InteractiveMarkerFeedback::MOUSE_UP) {
      std::array<double, kDof> q;
      {
        std::lock_guard<std::mutex> lock(joints_mtx_);
        q = current_joints_;
      }
      RCLCPP_INFO(
        this->get_logger(),
        "Joints: [%.5f, %.5f, %.5f, %.5f, %.5f, %.5f]",
        q[0], q[1], q[2], q[3], q[4], q[5]);
    }
  }
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<PoseTeacher>());
  rclcpp::shutdown();
  return 0;
}
