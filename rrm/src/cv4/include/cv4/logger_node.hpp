#pragma once

#include "rclcpp/rclcpp.hpp"
#include "sensor_msgs/msg/joint_state.hpp"
#include "rrm_msgs/srv/save_state.hpp"
#include "rrm_msgs/srv/command.hpp"
#include <vector>
#include <string>

class JointLogger : public rclcpp::Node {
public:
    JointLogger();

private:
    void joint_states_callback(const sensor_msgs::msg::JointState::SharedPtr msg);
    
    void save_callback(const std::shared_ptr<rrm_msgs::srv::SaveState::Request> request,
                       std::shared_ptr<rrm_msgs::srv::SaveState::Response> response);

    void play_callback(const std::shared_ptr<rrm_msgs::srv::SaveState::Request> request,
                       std::shared_ptr<rrm_msgs::srv::SaveState::Response> response);

    bool move_robot_to_point(const std::vector<double>& target, double velocity);

    rclcpp::Subscription<sensor_msgs::msg::JointState>::SharedPtr subscription_;
    rclcpp::Service<rrm_msgs::srv::SaveState>::SharedPtr service_save_;
    rclcpp::Service<rrm_msgs::srv::SaveState>::SharedPtr service_play_;
    rclcpp::Client<rrm_msgs::srv::Command>::SharedPtr client_move_;

    std::vector<double> current_positions_;
    int point_id_ = 0;
};