#include "cv6/logger_node.hpp"
#include "rclcpp/rclcpp.hpp"
#include "sensor_msgs/msg/joint_state.hpp"
#include "tf2_ros/transform_broadcaster.h"
#include "geometry_msgs/msg/transform_stamped.hpp"
#include <Eigen/Dense>
#include <map>

static std::shared_ptr<tf2_ros::TransformBroadcaster> tf_broadcaster = nullptr;

JointLogger::JointLogger() : Node("joint_logger") {
    subscription_ = this->create_subscription<sensor_msgs::msg::JointState>(
        "joint_states", 10, std::bind(&JointLogger::joint_states_callback, this, std::placeholders::_1)
    );
    if (!tf_broadcaster) tf_broadcaster = std::make_shared<tf2_ros::TransformBroadcaster>(this);
}

// Элементарные матрицы трансформации
static Eigen::Matrix4d rotZ(double q) {
    Eigen::Matrix4d T = Eigen::Matrix4d::Identity();
    T(0,0) = cos(q); T(0,1) = -sin(q);
    T(1,0) = sin(q); T(1,1) = cos(q);
    return T;
}

static Eigen::Matrix4d rotY(double q) {
    Eigen::Matrix4d T = Eigen::Matrix4d::Identity();
    T(0,0) = cos(q);  T(0,2) = sin(q);
    T(2,0) = -sin(q); T(2,2) = cos(q);
    return T;
}

static Eigen::Matrix4d transZ(double z) {
    Eigen::Matrix4d T = Eigen::Matrix4d::Identity();
    T(2,3) = z;
    return T;
}

void JointLogger::joint_states_callback(const sensor_msgs::msg::JointState::SharedPtr msg) {
    std::map<std::string, double> j;
    for (size_t i = 0; i < msg->name.size(); ++i) j[msg->name[i]] = msg->position[i];
    if (j.size() < 6) return;

    // Прямая цепочка согласно URDF (xyz offsets):
    // J1(Z) -> J2(Y) -> Z(0.203) -> J3(Y) -> Z(0.203) -> J4(Z) -> Z(0.05) -> J5(Y) -> Z(0.15 + q6) -> Tool
    
    Eigen::Matrix4d T = Eigen::Matrix4d::Identity();
    T = T * rotZ(j["joint_1"]);                       // J1 (Base Z)
    T = T * rotY(j["joint_2"]);                       // J2 (Shoulder Y)
    T = T * transZ(0.203) * rotY(j["joint_3"]);       // J3 (Elbow Y)
    T = T * transZ(0.203) * rotZ(j["joint_4"]);       // J4 (Wrist Z)
    T = T * transZ(0.05)  * rotY(j["joint_5"]);       // J5 (Wrist Y)
    T = T * transZ(0.15 + j["joint_6"]);              // J6 (Prismatic Z)

    RCLCPP_INFO_THROTTLE(this->get_logger(), *this->get_clock(), 500,
        "PRECISION Pose: X=%.3f, Y=%.3f, Z=%.3f", T(0,3), T(1,3), T(2,3));

    geometry_msgs::msg::TransformStamped ts;
    ts.header.stamp = this->get_clock()->now();
    ts.header.frame_id = "base_link";
    ts.child_frame_id = "tool0";
    ts.transform.translation.x = T(0,3);
    ts.transform.translation.y = T(1,3);
    ts.transform.translation.z = T(2,3);
    Eigen::Quaterniond q(T.block<3,3>(0,0));
    ts.transform.rotation.x = q.x(); ts.transform.rotation.y = q.y();
    ts.transform.rotation.z = q.z(); ts.transform.rotation.w = q.w();
    tf_broadcaster->sendTransform(ts);
}

int main(int argc, char **argv) {
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<JointLogger>());
    rclcpp::shutdown();
    return 0;
}