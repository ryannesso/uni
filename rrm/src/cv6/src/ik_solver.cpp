#include <rclcpp/rclcpp.hpp>
#include <Eigen/Dense>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>

#include "cv6/srv/compute_ik.hpp"
#include "cv6/srv/best_ik.hpp"

using ComputeIK = cv6::srv::ComputeIK;
using BestIK = cv6::srv::BestIK;

class IKSolver : public rclcpp::Node {
public:
  IKSolver() : Node("ik_solver") {
    this->declare_parameter<std::string>("robot_description", "");
    compute_srv_ = this->create_service<ComputeIK>("compute_ik",
      std::bind(&IKSolver::compute_cb, this, std::placeholders::_1, std::placeholders::_2));
    best_srv_ = this->create_service<BestIK>("best_ik",
      std::bind(&IKSolver::best_cb, this, std::placeholders::_1, std::placeholders::_2));
  }

private:
  rclcpp::Service<ComputeIK>::SharedPtr compute_srv_;
  rclcpp::Service<BestIK>::SharedPtr best_srv_;

  // Параметры из URDF
  const double L23 = 0.203; 
  const double L35 = 0.203 + 0.05; // 0.253 (L3 + L4)
  const double L56 = 0.15; 

  // Лимиты из таблицы
  const std::vector<double> low_lim = {-1.62, -0.96, -0.96, -3.14, -2.2, 0.0};
  const std::vector<double> upp_lim = { 1.62,  2.182,  2.182,  3.14,  2.2, 0.1};

  std::vector<std::array<double,6>> solve_ik_pose(const Eigen::Vector3d &pe, const Eigen::Quaterniond &qe, double q6_val) {
    std::vector<std::array<double,6>> sols;
    Eigen::Matrix3d R0e = qe.toRotationMatrix();
    Eigen::Vector3d z_end = R0e.col(2);
    
    // Позиция J5 (Wrist Center)
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
      // phi - угол от вертикали (Z) до вектора к точке
      // psi - угол между L23 и вектором до точки внутри треугольника
      double phi = std::atan2(r, h); 
      double psi = std::atan2(L35 * std::sin(q3), L23 + L35 * std::cos(q3));
      
      double q2 = phi - psi;

      // Ориентация: J4 в 0, J5 компенсирует наклон, чтобы инструмент был по кватерниону
      double q4 = 0.0;
      double q5 = - (q2 + q3); 

      std::array<double,6> sol = {q1, q2, q3, q4, q5, q6_val};
      
      bool ok = true;
      for(int i=0; i<6; i++) {
        if (i < 5) sol[i] = std::atan2(std::sin(sol[i]), std::cos(sol[i]));
        if (sol[i] < low_lim[i] - 0.05 || sol[i] > upp_lim[i] + 0.05) ok = false;
      }
      if (ok) sols.push_back(sol);
    }
    return sols;
  }

  void compute_cb(const std::shared_ptr<ComputeIK::Request> req, std::shared_ptr<ComputeIK::Response> res) {
    auto sols = solve_ik_pose({req->x, req->y, req->z}, {req->qw, req->qx, req->qy, req->qz}, 0.0);
    res->solution_count = static_cast<int>(sols.size());
    for (auto &s : sols) {
        for (double v : s) {
            res->solutions_flat.push_back(v); // Исправлено: v вместо val
        }
    }
  }

  void best_cb(const std::shared_ptr<BestIK::Request> req, std::shared_ptr<BestIK::Response> res) {
    double q6 = (req->current.size() >= 6) ? req->current[5] : 0.0;
    auto sols = solve_ik_pose({req->x, req->y, req->z}, {req->qw, req->qx, req->qy, req->qz}, q6);
    if (sols.empty()) { 
        res->success = false; 
        return; 
    }
    
    double min_d = 1e18;
    std::array<double,6> best_s;
    for (auto &s : sols) {
      double d = 0;
      for (int i=0; i<6; i++) d += std::pow(s[i] - (req->current.size()>i?req->current[i]:0.0), 2);
      if (d < min_d) { min_d = d; best_s = s; }
    }
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