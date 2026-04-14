#pragma once

#include <Eigen/Core>
#include <Eigen/Geometry>

#include <cstddef>
#include <vector>

namespace cv8_traj {

struct TrajectoryPoint
{
  // время точки относительно начала сегмента
  double t{0.0};
  // положение, скорость и ускорение в суставном пространстве
  Eigen::VectorXd q;
  Eigen::VectorXd qd;
  Eigen::VectorXd qdd;
};

class Manipulator
{
public:
  explicit Manipulator(std::size_t dof);

  // генерирует ptp quintic траекторию из q0 в q1
  std::vector<TrajectoryPoint> samplePtpQuintic(
    const Eigen::VectorXd & q0,
    const Eigen::VectorXd & q1,
    double duration_s,
    double dt_s) const;

  // генерирует ptp траекторию через via с непрерывным профилем
  std::vector<TrajectoryPoint> samplePtpVia(
    const Eigen::VectorXd & q_a,
    const Eigen::VectorXd & q_via,
    const Eigen::VectorXd & q_b,
    double duration_a_via_s,
    double duration_via_b_s,
    double dt_s) const;

  // генерирует набор декартовых поз для lin движения
  std::vector<Eigen::Affine3d> sampleLinPoses(
    const Eigen::Affine3d & start,
    const Eigen::Affine3d & goal,
    double duration_s,
    double dt_s) const;

  // сдвигает позу вдоль локальной оси x инструмента
  static Eigen::Affine3d offsetAlongToolX(const Eigen::Affine3d & pose, double offset_m);

private:
  std::size_t dof_;

  struct Quintic
  {
    // коэффициенты quintic полинома q(t)=a0+a1*t+...+a5*t^5
    Eigen::Matrix<double, 6, 1> a;
  };

  static Quintic quinticFromBoundary(
    double q0, double v0, double acc0,
    double q1, double v1, double acc1,
    double T);

  static void evalQuintic(
    const Quintic & poly,
    double t,
    double & q,
    double & qd,
    double & qdd);
};

}  // namespace cv8_traj
