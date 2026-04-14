#include <rclcpp/rclcpp.hpp>
#include <visualization_msgs/msg/marker.hpp>

#include <array>
#include <string>
#include <vector>

class ModelSpawner : public rclcpp::Node
{
public:
  ModelSpawner() : Node("model_spawner")
  {
    // параметры описывают источник mesh, позу и период переопубликования маркера
    this->declare_parameter<std::string>("frame_id", "base_link");
    this->declare_parameter<std::string>("marker_ns", "workpiece");
    this->declare_parameter<int>("marker_id", 0);
    this->declare_parameter<std::string>("mesh_resource", "");
    this->declare_parameter<double>("mesh_scale", 1.0);
    this->declare_parameter<std::vector<double>>("position", {0.8, 1.5, -0.5});
    this->declare_parameter<int>("publish_period_ms", 0);

    auto qos = rclcpp::QoS(rclcpp::KeepLast(1)).transient_local().reliable();
    pub_ = this->create_publisher<visualization_msgs::msg::Marker>("visualization_marker", qos);

    // публикует маркер сразу после старта, чтобы объект сразу появился в rviz
    publish();

    const int period_ms = this->get_parameter("publish_period_ms").as_int();
    if (period_ms > 0) {
      timer_ = this->create_wall_timer(std::chrono::milliseconds(period_ms), [this]() { publish(); });
    }
  }

private:
  rclcpp::Publisher<visualization_msgs::msg::Marker>::SharedPtr pub_;
  rclcpp::TimerBase::SharedPtr timer_;

  // формирует marker из параметров и отправляет его в visualization_marker
  void publish()
  {
    const std::string frame_id = this->get_parameter("frame_id").as_string();
    const std::string marker_ns = this->get_parameter("marker_ns").as_string();
    const int marker_id = this->get_parameter("marker_id").as_int();
    const std::string mesh_resource = this->get_parameter("mesh_resource").as_string();
    const double mesh_scale = this->get_parameter("mesh_scale").as_double();

    const auto pos = this->get_parameter("position").as_double_array();
    const double px = (pos.size() >= 1) ? pos[0] : 0.8;
    const double py = (pos.size() >= 2) ? pos[1] : 1.5;
    const double pz = (pos.size() >= 3) ? pos[2] : -0.5;

    visualization_msgs::msg::Marker m;
    m.header.frame_id = frame_id;
    m.header.stamp = this->now();
    m.ns = marker_ns;
    m.id = marker_id;
    if (!mesh_resource.empty()) {
      m.type = visualization_msgs::msg::Marker::MESH_RESOURCE;
      m.mesh_resource = mesh_resource;
    } else {
      m.type = visualization_msgs::msg::Marker::CUBE;
    }
    m.action = visualization_msgs::msg::Marker::ADD;

    // задает фиксированную позу объекта в base_link
    m.pose.position.x = px;
    m.pose.position.y = py;
    m.pose.position.z = pz;
    m.pose.orientation.w = 1.0;

    if (!mesh_resource.empty()) {
      const double s = (mesh_scale > 0.0) ? mesh_scale : 1.0;
      m.scale.x = s;
      m.scale.y = s;
      m.scale.z = s;
    } else {
      // размеры примитивного объекта, если mesh не задан
      m.scale.x = 0.25;
      m.scale.y = 0.12;
      m.scale.z = 0.06;
    }

    // нейтральный серый цвет модели
    m.color.r = 0.6f;
    m.color.g = 0.6f;
    m.color.b = 0.6f;
    m.color.a = 1.0f;

    pub_->publish(m);
  }
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<ModelSpawner>());
  rclcpp::shutdown();
  return 0;
}
