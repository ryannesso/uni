#include "rclcpp/rclcpp.hpp"
#include "rrm_msgs/srv/command.hpp"
#include "sensor_msgs/msg/joint_state.hpp" 
#include <iostream>
#include <vector>
#include <cmath>

class Teleop : public rclcpp::Node {
public:
    Teleop() : Node("Teleop") {
        client_ = this->create_client<rrm_msgs::srv::Command>("/move_command");
        
        subscription_ = this->create_subscription<sensor_msgs::msg::JointState>(
            "/joint_states", 10, 
            [this](const sensor_msgs::msg::JointState::SharedPtr msg) {
                current_positions_ = msg->position; 
            });
    }
    
    size_t get_joints_count() const { return current_positions_.size(); }

void move(const std::vector<double>& target, double max_vel) {
        if (current_positions_.empty()) return; 

        std::vector<double> dists(target.size());
        double max_d = 0;
        
        for(size_t i=0; i<target.size(); i++) {
            dists[i] = std::abs(target[i] - current_positions_[i]); 
            if(dists[i] > max_d) max_d = dists[i];
        }

        double time = (max_d > 0) ? (max_d / max_vel) : 0;
        std::vector<double> vels(target.size(), 0.0);
        
        if (time > 0) {
            for(size_t i=0; i<target.size(); i++) vels[i] = dists[i] / time;
        }

        auto req = std::make_shared<rrm_msgs::srv::Command::Request>();
        req->positions = target;
        req->velocities = vels;
        
    if (!client_->wait_for_service(std::chrono::seconds(1))) {
        RCLCPP_ERROR(this->get_logger(), "Service not available!");
        return;
    }

    // 2. Отправляем запрос
    auto future = client_->async_send_request(req);
    
    // 3. Ждем ответа, используя спиннинг (это важно!)
    // rclcpp::spin_until_future_complete "крутит" ROS, пока не придет ответ
    auto status = rclcpp::spin_until_future_complete(this->get_node_base_interface(), future, std::chrono::seconds(10));
    
    if (status == rclcpp::FutureReturnCode::SUCCESS) {
        auto response = future.get(); // Теперь это гарантированно не заблокирует код навсегда
        RCLCPP_INFO(this->get_logger(), "Response: %s (code: %d)", response->message.c_str(), response->result_code);
    } else {
        RCLCPP_ERROR(this->get_logger(), "Service call failed!");
    }
 }

private:
    rclcpp::Client<rrm_msgs::srv::Command>::SharedPtr client_;
    rclcpp::Subscription<sensor_msgs::msg::JointState>::SharedPtr subscription_;
    std::vector<double> current_positions_;
};

int main(int argc, char **argv) {
    rclcpp::init(argc, argv);
    auto robot = std::make_shared<Teleop>();

    while (rclcpp::ok() && robot->get_joints_count() == 0) {
        rclcpp::spin_some(robot);
    }

    size_t joints = robot->get_joints_count();
    std::cout << "ready. joints: " << joints << std::endl;

    while(rclcpp::ok()) {
        std::vector<double> pos(joints);
        double vel;
        
        std::cout << "\nwrite " << joints << " cords: ";
        for(size_t i=0; i<joints; i++) {
            std::cin >> pos[i];
        }
        
        std::cout << "speed: ";
        std::cin >> vel;

        robot->move(pos, vel);
        
        rclcpp::spin_some(robot); 
    }

    rclcpp::shutdown();
    return 0;
}
