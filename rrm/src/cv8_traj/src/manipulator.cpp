#include "cv8_traj/manipulator.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace cv8_traj {

Manipulator::Manipulator(std::size_t dof) : dof_(dof)
{
  if (dof_ == 0) {
    throw std::invalid_argument("Manipulator DOF must be > 0");
  }
}

Manipulator::Quintic Manipulator::quinticFromBoundary(
  double q0, double v0, double acc0,
  double q1, double v1, double acc1,
  double T)
{
  if (!(T > 0.0)) {
    throw std::invalid_argument("Quintic duration must be > 0");
  }

  Quintic poly;
  poly.a.setZero();

  poly.a(0) = q0;
  poly.a(1) = v0;
  poly.a(2) = 0.5 * acc0;

  // решает систему для неизвестных a3..a5 по граничным условиям в момент t=T
  const double T2 = T * T;
  const double T3 = T2 * T;
  const double T4 = T3 * T;
  const double T5 = T4 * T;

  Eigen::Matrix3d A;
  A <<
    T3, T4, T5,
    3.0 * T2, 4.0 * T3, 5.0 * T4,
    6.0 * T, 12.0 * T2, 20.0 * T3;

  Eigen::Vector3d b;
  const double q1_res = q1 - (poly.a(0) + poly.a(1) * T + poly.a(2) * T2);
  const double v1_res = v1 - (poly.a(1) + 2.0 * poly.a(2) * T);
  const double a1_res = acc1 - (2.0 * poly.a(2));
  b << q1_res, v1_res, a1_res;

  // по требованию задания используется явная обратная матрица
  const Eigen::Matrix3d A_inv = A.inverse();
  const Eigen::Vector3d x = A_inv * b;

  poly.a(3) = x(0);
  poly.a(4) = x(1);
  poly.a(5) = x(2);
  return poly;
}

void Manipulator::evalQuintic(
  const Quintic & poly,
  double t,
  double & q,
  double & qd,
  double & qdd)
{
  const double t2 = t * t;
  const double t3 = t2 * t;
  const double t4 = t3 * t;
  const double t5 = t4 * t;

  q = poly.a(0) + poly.a(1) * t + poly.a(2) * t2 + poly.a(3) * t3 + poly.a(4) * t4 + poly.a(5) * t5;
  qd = poly.a(1) + 2.0 * poly.a(2) * t + 3.0 * poly.a(3) * t2 + 4.0 * poly.a(4) * t3 + 5.0 * poly.a(5) * t4;
  qdd = 2.0 * poly.a(2) + 6.0 * poly.a(3) * t + 12.0 * poly.a(4) * t2 + 20.0 * poly.a(5) * t3;
}

std::vector<TrajectoryPoint> Manipulator::samplePtpQuintic(
  const Eigen::VectorXd & q0,
  const Eigen::VectorXd & q1,
  double duration_s,
  double dt_s) const
{
  if (q0.size() != static_cast<int>(dof_) || q1.size() != static_cast<int>(dof_)) {
    throw std::invalid_argument("PTP: q size mismatch");
  }
  if (!(duration_s > 0.0) || !(dt_s > 0.0)) {
    throw std::invalid_argument("PTP: duration/dt must be > 0");
  }

  // строит независимый quintic профиль для каждого сустава
  std::vector<Quintic> polys;
  polys.reserve(dof_);
  for (std::size_t i = 0; i < dof_; ++i) {
    polys.push_back(quinticFromBoundary(q0(i), 0.0, 0.0, q1(i), 0.0, 0.0, duration_s));
  }

  // дискретизирует траекторию по dt и возвращает q, qd, qdd для каждого шага
  const int steps = std::max(1, static_cast<int>(std::ceil(duration_s / dt_s)));
  std::vector<TrajectoryPoint> out;
  out.reserve(static_cast<std::size_t>(steps) + 1);

  for (int k = 0; k <= steps; ++k) {
    const double t = std::min(duration_s, k * dt_s);
    TrajectoryPoint pt;
    pt.t = t;
    pt.q = Eigen::VectorXd::Zero(dof_);
    pt.qd = Eigen::VectorXd::Zero(dof_);
    pt.qdd = Eigen::VectorXd::Zero(dof_);

    for (std::size_t i = 0; i < dof_; ++i) {
      double q, qd, qdd;
      evalQuintic(polys[i], t, q, qd, qdd);
      pt.q(static_cast<int>(i)) = q;
      pt.qd(static_cast<int>(i)) = qd;
      pt.qdd(static_cast<int>(i)) = qdd;
    }

    out.push_back(std::move(pt));
  }

  return out;
}

std::vector<TrajectoryPoint> Manipulator::samplePtpVia(
  const Eigen::VectorXd & q_a,
  const Eigen::VectorXd & q_via,
  const Eigen::VectorXd & q_b,
  double duration_a_via_s,
  double duration_via_b_s,
  double dt_s) const
{
  if (q_a.size() != static_cast<int>(dof_) || q_via.size() != static_cast<int>(dof_) || q_b.size() != static_cast<int>(dof_)) {
    throw std::invalid_argument("PTP via: q size mismatch");
  }
  if (!(duration_a_via_s > 0.0) || !(duration_via_b_s > 0.0) || !(dt_s > 0.0)) {
    throw std::invalid_argument("PTP via: duration/dt must be > 0");
  }

  // подбирает скорость в via, чтобы обеспечить непрерывность профиля в точке стыка
  Eigen::VectorXd v_via = Eigen::VectorXd::Zero(dof_);
  for (std::size_t i = 0; i < dof_; ++i) {
    const double slope1 = (q_via(i) - q_a(i)) / duration_a_via_s;
    const double slope2 = (q_b(i) - q_via(i)) / duration_via_b_s;
    v_via(static_cast<int>(i)) = 0.5 * (slope1 + slope2);
  }

  // если оценка почти нулевая, использует глобальный наклон от a к b
  if (v_via.norm() < 1e-6) {
    const double total = duration_a_via_s + duration_via_b_s;
    v_via = (q_b - q_a) / total;
  }

  // строит два сегмента: a->via и via->b, затем сшивает их по времени
  std::vector<Quintic> poly1;
  std::vector<Quintic> poly2;
  poly1.reserve(dof_);
  poly2.reserve(dof_);
  for (std::size_t i = 0; i < dof_; ++i) {
    poly1.push_back(quinticFromBoundary(q_a(i), 0.0, 0.0, q_via(i), v_via(i), 0.0, duration_a_via_s));
    poly2.push_back(quinticFromBoundary(q_via(i), v_via(i), 0.0, q_b(i), 0.0, 0.0, duration_via_b_s));
  }

  const double total = duration_a_via_s + duration_via_b_s;
  const int steps = std::max(1, static_cast<int>(std::ceil(total / dt_s)));

  std::vector<TrajectoryPoint> out;
  out.reserve(static_cast<std::size_t>(steps) + 1);

  for (int k = 0; k <= steps; ++k) {
    const double t = std::min(total, k * dt_s);

    TrajectoryPoint pt;
    pt.t = t;
    pt.q = Eigen::VectorXd::Zero(dof_);
    pt.qd = Eigen::VectorXd::Zero(dof_);
    pt.qdd = Eigen::VectorXd::Zero(dof_);

    const bool in_first = (t <= duration_a_via_s);
    const double local_t = in_first ? t : (t - duration_a_via_s);

    for (std::size_t i = 0; i < dof_; ++i) {
      double q, qd, qdd;
      if (in_first) {
        evalQuintic(poly1[i], local_t, q, qd, qdd);
      } else {
        evalQuintic(poly2[i], local_t, q, qd, qdd);
      }
      pt.q(static_cast<int>(i)) = q;
      pt.qd(static_cast<int>(i)) = qd;
      pt.qdd(static_cast<int>(i)) = qdd;
    }

    out.push_back(std::move(pt));
  }

  return out;
}

std::vector<Eigen::Affine3d> Manipulator::sampleLinPoses(
  const Eigen::Affine3d & start,
  const Eigen::Affine3d & goal,
  double duration_s,
  double dt_s) const
{
  if (!(duration_s > 0.0) || !(dt_s > 0.0)) {
    throw std::invalid_argument("LIN: duration/dt must be > 0");
  }

  // для lin сохраняет ориентацию стартовой позы и интерполирует только позицию
  const Eigen::Vector3d p0 = start.translation();
  const Eigen::Vector3d p1 = goal.translation();
  const Eigen::Matrix3d R = start.rotation();

  const int steps = std::max(1, static_cast<int>(std::ceil(duration_s / dt_s)));
  std::vector<Eigen::Affine3d> out;
  out.reserve(static_cast<std::size_t>(steps) + 1);

  for (int k = 0; k <= steps; ++k) {
    const double t = std::min(duration_s, k * dt_s);
    const double tau = t / duration_s;

    // quintic time scaling для плавного старта и остановки по декартовой координате
    const double s = 10.0 * std::pow(tau, 3) - 15.0 * std::pow(tau, 4) + 6.0 * std::pow(tau, 5);

    Eigen::Affine3d pose = Eigen::Affine3d::Identity();
    pose.linear() = R;
    pose.translation() = p0 + (p1 - p0) * s;
    out.push_back(pose);
  }

  return out;
}

Eigen::Affine3d Manipulator::offsetAlongToolX(const Eigen::Affine3d & pose, double offset_m)
{
  // сдвигает позу вдоль локальной оси x инструмента
  Eigen::Affine3d out = pose;
  out.translation() = pose.translation() + offset_m * (pose.rotation() * Eigen::Vector3d::UnitX());
  return out;
}

}  // namespace cv8_traj
