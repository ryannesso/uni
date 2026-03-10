#include "cv4/logger_node.hpp"
#include <fstream>
#include <sstream>
#include <cmath>

JointLogger::JointLogger() : Node("joint_logger") {
    subscription_ = this->create_subscription<sensor_msgs::msg::JointState>(
        "/joint_states", 
        rclcpp::SensorDataQoS(), 
        std::bind(&JointLogger::joint_states_callback, this, std::placeholders::_1)
    );

    service_save_ = this->create_service<rrm_msgs::srv::SaveState>(
        "/save_position",
        std::bind(&JointLogger::save_callback, this, std::placeholders::_1, std::placeholders::_2)
    );

    service_play_ = this->create_service<rrm_msgs::srv::SaveState>(
        "/play_trajectory",
        std::bind(&JointLogger::play_callback, this, std::placeholders::_1, std::placeholders::_2)
    );

    client_move_ = this->create_client<rrm_msgs::srv::Command>("/move_command");

    RCLCPP_INFO(this->get_logger(), "JointLogger ready. Services: /save_position, /play_trajectory");
}

void JointLogger::joint_states_callback(const sensor_msgs::msg::JointState::SharedPtr msg) {
    current_positions_ = msg->position;
}

void JointLogger::save_callback(const std::shared_ptr<rrm_msgs::srv::SaveState::Request> request,
                                std::shared_ptr<rrm_msgs::srv::SaveState::Response> response) 
{
    if (current_positions_.empty()) {
        response->success = false;
        response->message = "No position data available.";
        return;
    }

    std::ofstream file("trajectory.txt", std::ios::app);
    if (file.is_open()) {
        file << point_id_ << " ";
        for (double pos : current_positions_) {
            file << pos << " ";
        }
        file << request->max_velocity << "\n";
        file.close();

        response->success = true;
        response->message = "Point " + std::to_string(point_id_) + " saved.";
        RCLCPP_INFO(this->get_logger(), "Saved point ID: %d", point_id_);
        point_id_++;
    } else {
        response->success = false;
        response->message = "Failed to open file.";
    }
}

void JointLogger::play_callback(const std::shared_ptr<rrm_msgs::srv::SaveState::Request>,
                                std::shared_ptr<rrm_msgs::srv::SaveState::Response> response)
{
    std::ifstream file("trajectory.txt");
    if (!file.is_open()) {
        response->success = false;
        response->message = "File trajectory.txt not found.";
        return;
    }

    std::string line;
    int points_played = 0;
    
    RCLCPP_INFO(this->get_logger(), "Starting trajectory playback...");

    while (std::getline(file, line)) {
        std::stringstream ss(line);
        int id;
        double val;
        std::vector<double> numbers;
        
        ss >> id; 
        
        while (ss >> val) {
            numbers.push_back(val);
        }

        if (numbers.empty()) continue;

        double velocity = numbers.back();
        numbers.pop_back(); 
        std::vector<double> target_positions = numbers;

        RCLCPP_INFO(this->get_logger(), "Moving to point ID: %d with velocity %.2f", id, velocity);

        if (!move_robot_to_point(target_positions, velocity)) {
            RCLCPP_ERROR(this->get_logger(), "Failed to move to point ID: %d", id);
        }
        points_played++;
    }
    
    file.close();
    response->success = true;
    response->message = "Played points: " + std::to_string(points_played);
}

bool JointLogger::move_robot_to_point(const std::vector<double>& target, double max_vel) {
    if (current_positions_.empty()) return false;

    std::vector<double> dists(target.size());
    double max_dist = 0;
    for(size_t i=0; i<target.size(); i++) {
        dists[i] = std::abs(target[i] - current_positions_[i]);
        if(dists[i] > max_dist) max_dist = dists[i];
    }

    double time = (max_dist > 0) ? (max_dist / max_vel) : 0;
    std::vector<double> vels(target.size(), 0.0);
    if (time > 0) {
        for(size_t i=0; i<target.size(); i++) vels[i] = dists[i] / time;
    }

    auto req = std::make_shared<rrm_msgs::srv::Command::Request>();
    req->positions = target;
    req->velocities = vels;

    if (!client_move_->wait_for_service(std::chrono::seconds(1))) {
        return false;
    }

    auto future = client_move_->async_send_request(req);
    
    if (future.wait_for(std::chrono::seconds(10)) == std::future_status::ready) {
        return future.get()->result_code == 0;
    }
    
    return false;
}

int main(int argc, char **argv) {
    rclcpp::init(argc, argv);
    auto logger = std::make_shared<JointLogger>();
    rclcpp::executors::MultiThreadedExecutor executor;
    executor.add_node(logger);
    executor.spin();
    rclcpp::shutdown();
    return 0;
}