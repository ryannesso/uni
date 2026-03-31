#include <rclcpp/rclcpp.hpp>
#include <Eigen/Dense>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <urdf/model.h> // Библиотека для работы с URDF

#include "cv6/srv/compute_ik.hpp"
#include "cv6/srv/best_ik.hpp"

using ComputeIK = cv6::srv::ComputeIK;
using BestIK = cv6::srv::BestIK;

class IKSolver : public rclcpp::Node {
public:
  IKSolver() : Node("ik_solver") {
    // 1. Декларируем параметр. Обычно robot_state_publisher закидывает сюда URDF.
    this->declare_parameter<std::string>("robot_description", "");

    // Пытаемся получить URDF сразу при запуске
    std::string urdf_xml;
    if (this->get_parameter("robot_description", urdf_xml) && !urdf_xml.empty()) {
      load_limits_from_urdf(urdf_xml);
    }

    compute_srv_ = this->create_service<ComputeIK>("compute_ik",
      std::bind(&IKSolver::compute_cb, this, std::placeholders::_1, std::placeholders::_2));
    best_srv_ = this->create_service<BestIK>("best_ik",
      std::bind(&IKSolver::best_cb, this, std::placeholders::_1, std::placeholders::_2));

    // 2. Добавляем коллбэк на изменение параметров (если URDF придет позже)
    param_cb_ = this->add_on_set_parameters_callback(
      [this](const std::vector<rclcpp::Parameter> &parameters) {
        rcl_interfaces::msg::SetParametersResult result;
        result.successful = true;
        for (const auto &param : parameters) {
          if (param.get_name() == "robot_description") {
            load_limits_from_urdf(param.as_string());
          }
        }
        return result;
      });
  }

private:
  rclcpp::Service<ComputeIK>::SharedPtr compute_srv_;
  rclcpp::Service<BestIK>::SharedPtr best_srv_;
  rclcpp::node_interfaces::OnSetParametersCallbackHandle::SharedPtr param_cb_;

  // Параметры звеньев (остаются из URDF/схемы)
  const double L23 = 0.203; 
  const double L35 = 0.253; 
  const double L56 = 0.15; 

  // Векторы лимитов, которые мы заполним из URDF
  std::vector<double> low_lim = {-M_PI, -M_PI, -M_PI, -M_PI, -M_PI, 0.0};
  std::vector<double> upp_lim = { M_PI,  M_PI,  M_PI,  M_PI,  M_PI, 0.1};

  // Метод для парсинга URDF
  void load_limits_from_urdf(const std::string &xml_string) {
    urdf::Model model;
    if (!model.initString(xml_string)) {
      RCLCPP_ERROR(this->get_logger(), "Failed to parse URDF from robot_description");
      return;
    }

    RCLCPP_INFO(this->get_logger(), "Successfully parsed URDF. Loading joint limits...");

    for (int i = 1; i <= 6; ++i) {
      std::string joint_name = "joint_" + std::to_string(i);
      auto joint = model.getJoint(joint_name);

      if (joint && joint->limits) {
        low_lim[i-1] = joint->limits->lower;
        upp_lim[i-1] = joint->limits->upper;
        RCLCPP_INFO(this->get_logger(), "Joint %s limits: [%.3f, %.3f]", 
                    joint_name.c_str(), low_lim[i-1], upp_lim[i-1]);
      } else {
        RCLCPP_WARN(this->get_logger(), "Joint %s not found or has no limits in URDF!", joint_name.c_str());
      }
    }
  }

  // Математика IK (без изменений)
  std::vector<std::array<double,6>> solve_ik_pose(const Eigen::Vector3d &pe, const Eigen::Quaterniond &qe, double q6_val) {
    std::vector<std::array<double,6>> sols;
    Eigen::Matrix3d R0e = qe.toRotationMatrix();
    Eigen::Vector3d z_end = R0e.col(2);
    Eigen::Vector3d p5 = pe - (L56 + q6_val) * z_end;

    double x = p5.x(), y = p5.y(), z = p5.z();
    double q1 = std::atan2(y, x);
    double r = std::sqrt(x*x + y*y);
    double h = z; 

    double dist_sq = r*r + h*h;
    double D = (dist_sq - L23*L23 - L35*L35) / (2.0 * L23 * L35);

    if (std::abs(D) > 1.0) return sols; 

    double q3_base = std::acos(D);
    std::vector<double> q3_opts = { q3_base, -q3_base };

    for (double q3 : q3_opts) {
      double phi = std::atan2(r, h); 
      double psi = std::atan2(L35 * std::sin(q3), L23 + L35 * std::cos(q3));
      double q2 = phi - psi;
      double q4 = 0.0;
      double q5 = - (q2 + q3); 

      std::array<double,6> sol = {q1, q2, q3, q4, q5, q6_val};
      
      bool ok = true;
      for(int i=0; i<6; i++) {
        if (i < 5) sol[i] = std::atan2(std::sin(sol[i]), std::cos(sol[i]));
        // Используем динамические лимиты из URDF
        if (sol[i] < low_lim[i] - 0.01 || sol[i] > upp_lim[i] + 0.01) ok = false;
      }
      if (ok) sols.push_back(sol);
    }
    return sols;
  }

  void compute_cb(const std::shared_ptr<ComputeIK::Request> req, std::shared_ptr<ComputeIK::Response> res) {
    auto sols = solve_ik_pose({req->x, req->y, req->z}, {req->qw, req->qx, req->qy, req->qz}, 0.0);
    res->solution_count = static_cast<int>(sols.size());
    for (auto &s : sols) {
        for (double v : s) res->solutions_flat.push_back(v);
    }
  }

  void best_cb(const std::shared_ptr<BestIK::Request> req, std::shared_ptr<BestIK::Response> res) {
    double q6 = (req->current.size() >= 6) ? req->current[5] : 0.0;
    auto sols = solve_ik_pose({req->x, req->y, req->z}, {req->qw, req->qx, req->qy, req->qz}, q6);
    if (sols.empty()) { res->success = false; return; }
    
    double min_d = 1e18;
    std::array<double,6> best_s;
    for (auto &s : sols) {
      double d = 0;
      for (int i=0; i<6; i++) d += std::pow(s[i] - (req->current.size()>i?req->current[i]:0.0), 2);
      if (d < min_d) { min_d = d; best_s = s; }
    }
    
    RCLCPP_INFO(this->get_logger(), "Best Solution: [%.3f, %.3f, %.3f, %.3f, %.3f, %.3f]",
                best_s[0], best_s[1], best_s[2], best_s[3], best_s[4], best_s[5]);

    res->solution = std::vector<double>(best_s.begin(), best_s.end());
    res->success = true;
  }
};

int main(int argc, char **argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<IKSolver>());
  rclcpp::shutdown();
  return 0;
}