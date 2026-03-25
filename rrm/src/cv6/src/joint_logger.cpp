#include "cv6/logger_node.hpp"
#include "rclcpp/rclcpp.hpp"
#include "sensor_msgs/msg/joint_state.hpp"
#include "tf2_ros/transform_broadcaster.h"
#include "geometry_msgs/msg/transform_stamped.hpp"
#include <Eigen/Dense>
#include <map>
#include <cmath>

static std::shared_ptr<tf2_ros::TransformBroadcaster> tf_broadcaster = nullptr;

JointLogger::JointLogger() : Node("joint_logger") {
    subscription_ = this->create_subscription<sensor_msgs::msg::JointState>(
        "joint_states", 10, std::bind(&JointLogger::joint_states_callback, this, std::placeholders::_1)
    );
    if (!tf_broadcaster) tf_broadcaster = std::make_shared<tf2_ros::TransformBroadcaster>(this);
    RCLCPP_INFO(this->get_logger(), "JointLogger: DH Method Initialized");
}


Eigen::Matrix4d get_dh_matrix(double a, double alpha_deg, double d, double theta_rad) {
    double alpha_rad = alpha_deg * M_PI / 180.0;
    Eigen::Matrix4d T;
    T << cos(theta_rad), -sin(theta_rad) * cos(alpha_rad),  sin(theta_rad) * sin(alpha_rad), a * cos(theta_rad),
         sin(theta_rad),  cos(theta_rad) * cos(alpha_rad), -cos(theta_rad) * sin(alpha_rad), a * sin(theta_rad),
         0,               sin(alpha_rad),                   cos(alpha_rad),                  d,
         0,               0,                                0,                               1;
    return T;
}

void JointLogger::joint_states_callback(const sensor_msgs::msg::JointState::SharedPtr msg) {
    std::map<std::string, double> j;
    for (size_t i = 0; i < msg->name.size(); ++i) j[msg->name[i]] = msg->position[i];
    if (j.size() < 6) return;

    const double L2 = 0.203;
    const double L34 = 0.253; 
    const double L56 = 0.15;  // L5


    Eigen::Matrix4d T = Eigen::Matrix4d::Identity();

    // i=1: a=0, alpha=90, d=0, theta = q1 + 180deg
    T = T * get_dh_matrix(0.0, 90.0, 0.0, j["joint_1"] + M_PI);

    // i=2: a=L2, alpha=0, d=0, theta = q2 + 90deg
    T = T * get_dh_matrix(L2, 0.0, 0.0, j["joint_2"] + M_PI/2.0);

    // i=3: a=0, alpha=90, d=0, theta = q3 + 90deg
    T = T * get_dh_matrix(0.0, 90.0, 0.0, j["joint_3"] + M_PI/2.0);

    // i=4: a=0, alpha=90, d=L34, theta = q4 + 180deg
    T = T * get_dh_matrix(0.0, 90.0, L34, j["joint_4"] + M_PI);

    // i=5: a=0, alpha=90, d=0, theta = q5 + 180deg
    T = T * get_dh_matrix(0.0, 90.0, 0.0, j["joint_5"] + M_PI);

    // i=6: a=0, alpha=0, d=L56 + q6, theta = 0 (J6 prismatic)
    T = T * get_dh_matrix(0.0, 0.0, L56 + j["joint_6"], 0.0);

    geometry_msgs::msg::TransformStamped ts;
    ts.header.stamp = this->get_clock()->now();
    ts.header.frame_id = "base_link";
    ts.child_frame_id = "tool0";
    
    ts.transform.translation.x = T(0,3);
    ts.transform.translation.y = T(1,3);
    ts.transform.translation.z = T(2,3);

    Eigen::Quaterniond q(T.block<3,3>(0,0));
    ts.transform.rotation.x = q.x();
    ts.transform.rotation.y = q.y();
    ts.transform.rotation.z = q.z();
    ts.transform.rotation.w = q.w();

    tf_broadcaster->sendTransform(ts);

    RCLCPP_INFO_THROTTLE(this->get_logger(), *this->get_clock(), 1000,
        "DH Position: X=%.3f, Y=%.3f, Z=%.3f", T(0,3), T(1,3), T(2,3));
}

int main(int argc, char **argv) {
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<JointLogger>());
    rclcpp::shutdown();
    return 0;
}