// generated from rosidl_generator_cpp/resource/idl__builder.hpp.em
// with input from rrm_msgs:msg/Command.idl
// generated code does not contain a copyright notice

#ifndef RRM_MSGS__MSG__DETAIL__COMMAND__BUILDER_HPP_
#define RRM_MSGS__MSG__DETAIL__COMMAND__BUILDER_HPP_

#include <algorithm>
#include <utility>

#include "rrm_msgs/msg/detail/command__struct.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


namespace rrm_msgs
{

namespace msg
{

namespace builder
{

class Init_Command_position
{
public:
  explicit Init_Command_position(::rrm_msgs::msg::Command & msg)
  : msg_(msg)
  {}
  ::rrm_msgs::msg::Command position(::rrm_msgs::msg::Command::_position_type arg)
  {
    msg_.position = std::move(arg);
    return std::move(msg_);
  }

private:
  ::rrm_msgs::msg::Command msg_;
};

class Init_Command_joint_id
{
public:
  Init_Command_joint_id()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  Init_Command_position joint_id(::rrm_msgs::msg::Command::_joint_id_type arg)
  {
    msg_.joint_id = std::move(arg);
    return Init_Command_position(msg_);
  }

private:
  ::rrm_msgs::msg::Command msg_;
};

}  // namespace builder

}  // namespace msg

template<typename MessageType>
auto build();

template<>
inline
auto build<::rrm_msgs::msg::Command>()
{
  return rrm_msgs::msg::builder::Init_Command_joint_id();
}

}  // namespace rrm_msgs

#endif  // RRM_MSGS__MSG__DETAIL__COMMAND__BUILDER_HPP_
