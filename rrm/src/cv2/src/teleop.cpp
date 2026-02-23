#include "rclcpp/rclcpp.hpp"
#include "rrm_msgs/msg/command.hpp"
#include <iostream>
class Teleop : public rclcpp::Node {
    public:
    Teleop() : Node("Teleop") {
        RCLCPP_INFO(this->get_logger(), "Teleop initialized");
        publisher_ = this->create_publisher<rrm_msgs::msg::Command>("move_command", 10);
    }
    void move(int joint_id, double position) {
        rrm_msgs::msg::Command message;
        message.joint_id = joint_id;
        message.position = position;
        publisher_->publish(message);

    }
    private:
        rclcpp::Publisher<rrm_msgs::msg::Command>::SharedPtr publisher_;
};
int main(int argc, char **argv) {
    rclcpp::init(argc, argv);
    Teleop robot;
    int joint_id = 0;
    double position = 0.0;
    while(rclcpp::ok()) {
        std::cout << "input join and position: ";
        std::cin >> joint_id >> position;
        robot.move(joint_id, position);
    }
    rclcpp::shutdown();
    return 0;
}