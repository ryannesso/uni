#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/joint_state.hpp>
#include "cv6/srv/move_to_cartesian.hpp"
#include "cv6/srv/best_ik.hpp"
#include "rrm_msgs/srv/command.hpp"
#include <memory>
#include <vector>

using MoveToCartesian = cv6::srv::MoveToCartesian;
using BestIK = cv6::srv::BestIK;
using MoveCmd = rrm_msgs::srv::Command;

class MotionManager : public rclcpp::Node {
public:
  MotionManager() : Node("motion_manager") {
    // 1. Создаем группу коллбеков для сервиса, чтобы он мог обрабатываться в отдельном потоке
    srv_cb_group_ = this->create_callback_group(rclcpp::CallbackGroupType::MutuallyExclusive);
    
    // Создаем подписчика (Callback Group по умолчанию)
    sub_ = this->create_subscription<sensor_msgs::msg::JointState>(
      "/joint_states", 10, std::bind(&MotionManager::js_cb, this, std::placeholders::_1));

    // 2. Добавляем сервис в созданную Callback Group
    service_ = this->create_service<MoveToCartesian>(
      "move_to_cartesian",
      std::bind(&MotionManager::move_cb, this, std::placeholders::_1, std::placeholders::_2),
      rmw_qos_profile_services_default,
      srv_cb_group_);

    // Клиенты (Callback Group по умолчанию)
    ik_client_ = this->create_client<BestIK>("best_ik");
    move_client_ = this->create_client<MoveCmd>("move_command");
    RCLCPP_INFO(this->get_logger(), "MotionManager ready");
  }

private:
  rclcpp::CallbackGroup::SharedPtr srv_cb_group_;
  rclcpp::Subscription<sensor_msgs::msg::JointState>::SharedPtr sub_;
  rclcpp::Service<MoveToCartesian>::SharedPtr service_;
  rclcpp::Client<BestIK>::SharedPtr ik_client_;
  rclcpp::Client<MoveCmd>::SharedPtr move_client_;
  std::vector<double> current_joints_;

  void js_cb(const sensor_msgs::msg::JointState::SharedPtr msg) {
    current_joints_ = msg->position;
  }

  void move_cb(const std::shared_ptr<MoveToCartesian::Request> req,
               std::shared_ptr<MoveToCartesian::Response> res) {
    if (current_joints_.empty()) {
      res->success = false;
      res->message = "No joint states received yet";
      return;
    }

    if (!ik_client_->wait_for_service(std::chrono::seconds(2))) {
      res->success = false; res->message = "IK service unavailable"; return;
    }
    
    auto ik_req = std::make_shared<BestIK::Request>();
    ik_req->x = req->x; ik_req->y = req->y; ik_req->z = req->z;
    ik_req->qx = req->qx; ik_req->qy = req->qy; ik_req->qz = req->qz; ik_req->qw = req->qw;
    ik_req->current = current_joints_;

    auto ik_future = ik_client_->async_send_request(ik_req);
    
    // Внимание: мы ждем ответа, но теперь это не вызовет краш, т.к. этот сервис крутится в своем потоке 
    // благодаря MultiThreadedExecutor в main()
    auto status = ik_future.wait_for(std::chrono::seconds(2));
    if (status != std::future_status::ready) {
      res->success = false; res->message = "IK service call timed out"; return;
    }

    auto ik_res = ik_future.get();
    if (!ik_res->success) { res->success = false; res->message = "IK solver found no valid solution"; return; }

    if (!move_client_->wait_for_service(std::chrono::seconds(2))) {
      res->success = false; res->message = "move_command service unavailable"; return;
    }
    
    auto move_req = std::make_shared<MoveCmd::Request>();
    move_req->positions = ik_res->solution;
    move_req->velocities = std::vector<double>(ik_res->solution.size(), 0.1);

    auto move_future = move_client_->async_send_request(move_req);
    status = move_future.wait_for(std::chrono::seconds(10));
    if (status != std::future_status::ready) {
      res->success = false; res->message = "move_command call timed out"; return;
    }

    auto move_res = move_future.get();
    bool ok = true;
    try {
      ok = (move_res->result_code == 0);
      res->message = move_res->message;
    } catch (...) {
      res->message = "Move command returned (no result_code field)";
    }
    res->success = ok;
  }
};

int main(int argc, char **argv) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<MotionManager>();
  
  // 3. Используем многопоточный экзекутор
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin(); // Крутим ноду в нескольких потоках
  
  rclcpp::shutdown();
  return 0;
}