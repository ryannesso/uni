#include "rclcpp/rclcpp.hpp"
#include "rrm_msgs/srv/command.hpp"
#include "sensor_msgs/msg/joint_state.hpp" 
#include <iostream>
#include <vector>
#include <cmath>
#include <algorithm> // Добавлено для std::clamp
#include <chrono>

class Teleop : public rclcpp::Node {
public:
    Teleop() : Node("Teleop") {
        client_ = this->create_client<rrm_msgs::srv::Command>("/move_command");
        
        subscription_ = this->create_subscription<sensor_msgs::msg::JointState>(
            "/joint_states", 10,[this](const sensor_msgs::msg::JointState::SharedPtr msg) {
                current_positions_ = msg->position; 
            });
    }
    
    size_t get_joints_count() const { return current_positions_.size(); }

    void move(const std::vector<double>& target, double max_vel) {
        if (current_positions_.empty()) return; 
        if (target.size() != current_positions_.size()) {
            RCLCPP_ERROR(this->get_logger(), "Target size != current joint count, skipping command");
            return;
        }

        std::vector<double> dists(target.size());
        double max_d = 0;
        
        for(size_t i=0; i<target.size(); i++) {
            dists[i] = std::abs(target[i] - current_positions_[i]); 
            if(dists[i] > max_d) max_d = dists[i];
        }

        if (max_d == 0.0) {
            RCLCPP_INFO(this->get_logger(), "Already at target positions, skipping command");
            return;
        }

        double time = (max_d > 0) ? (max_d / max_vel) : 0;
        std::vector<double> vels(target.size(), 0.0);
        
        if (time > 0) {
            for(size_t i=0; i<target.size(); i++) vels[i] = dists[i] / time;
        }

        auto req = std::make_shared<rrm_msgs::srv::Command::Request>();
        req->positions = target;
        req->velocities = vels;
        
        if(client_->wait_for_service(std::chrono::seconds(5))) {
            auto result_future = client_->async_send_request(req);
            using rclcpp::FutureReturnCode;
            if (rclcpp::spin_until_future_complete(this->get_node_base_interface(), result_future, std::chrono::seconds(2)) == FutureReturnCode::SUCCESS) {
                auto res = result_future.get();
                RCLCPP_INFO(this->get_logger(), "Service response: %s", res->message.c_str());
            } else {
                RCLCPP_WARN(this->get_logger(), "Service call did not complete in time");
            }
        } else {
            RCLCPP_ERROR(this->get_logger(), "Service unavailable");
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

    // Лимиты из вашей таблицы для J1 - J6
    const std::vector<double> lower_limits = {-1.62, -0.96, -0.96, -3.14, -2.2, 0.0};
    const std::vector<double> upper_limits = { 1.62,  2.182,  2.182,  3.14,  2.2, 0.1};

    while(rclcpp::ok()) {
        std::vector<double> pos(joints);
        double vel;
        bool bad_input = false;
        
        std::cout << "\nwrite " << joints << " cords: ";
        for(size_t i=0; i<joints; i++) {
            if(!(std::cin >> pos[i])) {
                std::cin.clear();
                std::string dummy;
                std::getline(std::cin, dummy);
                std::cout << "[ERROR] Invalid input for joint " << (i+1) << ". Try again.\n";
                bad_input = true;
                break;
            }
            
            // Защита от выхода за пределы (если ввели 6 координат)
            if (joints == 6) {
                double clamped = std::clamp(pos[i], lower_limits[i], upper_limits[i]);
                if (clamped != pos[i]) {
                    std::cout << "[WARN] Joint " << i+1 << " out of limits. Clamped to " << clamped << "\n";
                    pos[i] = clamped;
                }
            }
        }

        if (bad_input) {
            continue;
        }
        
        std::cout << "speed: ";
        if(!(std::cin >> vel)) {
            std::cin.clear();
            std::string dummy;
            std::getline(std::cin, dummy);
            std::cout << "[ERROR] Invalid speed. Try again.\n";
            continue;
        }

        robot->move(pos, vel);
        
        rclcpp::spin_some(robot); 
    }

    rclcpp::shutdown();
    return 0;
}