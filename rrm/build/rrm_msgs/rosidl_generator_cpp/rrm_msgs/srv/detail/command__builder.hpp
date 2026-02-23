// generated from rosidl_generator_cpp/resource/idl__builder.hpp.em
// with input from rrm_msgs:srv/Command.idl
// generated code does not contain a copyright notice

#ifndef RRM_MSGS__SRV__DETAIL__COMMAND__BUILDER_HPP_
#define RRM_MSGS__SRV__DETAIL__COMMAND__BUILDER_HPP_

#include <algorithm>
#include <utility>

#include "rrm_msgs/srv/detail/command__struct.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


namespace rrm_msgs
{

namespace srv
{

namespace builder
{

class Init_Command_Request_velocities
{
public:
  explicit Init_Command_Request_velocities(::rrm_msgs::srv::Command_Request & msg)
  : msg_(msg)
  {}
  ::rrm_msgs::srv::Command_Request velocities(::rrm_msgs::srv::Command_Request::_velocities_type arg)
  {
    msg_.velocities = std::move(arg);
    return std::move(msg_);
  }

private:
  ::rrm_msgs::srv::Command_Request msg_;
};

class Init_Command_Request_positions
{
public:
  Init_Command_Request_positions()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  Init_Command_Request_velocities positions(::rrm_msgs::srv::Command_Request::_positions_type arg)
  {
    msg_.positions = std::move(arg);
    return Init_Command_Request_velocities(msg_);
  }

private:
  ::rrm_msgs::srv::Command_Request msg_;
};

}  // namespace builder

}  // namespace srv

template<typename MessageType>
auto build();

template<>
inline
auto build<::rrm_msgs::srv::Command_Request>()
{
  return rrm_msgs::srv::builder::Init_Command_Request_positions();
}

}  // namespace rrm_msgs


namespace rrm_msgs
{

namespace srv
{

namespace builder
{

class Init_Command_Response_message
{
public:
  explicit Init_Command_Response_message(::rrm_msgs::srv::Command_Response & msg)
  : msg_(msg)
  {}
  ::rrm_msgs::srv::Command_Response message(::rrm_msgs::srv::Command_Response::_message_type arg)
  {
    msg_.message = std::move(arg);
    return std::move(msg_);
  }

private:
  ::rrm_msgs::srv::Command_Response msg_;
};

class Init_Command_Response_result_code
{
public:
  Init_Command_Response_result_code()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  Init_Command_Response_message result_code(::rrm_msgs::srv::Command_Response::_result_code_type arg)
  {
    msg_.result_code = std::move(arg);
    return Init_Command_Response_message(msg_);
  }

private:
  ::rrm_msgs::srv::Command_Response msg_;
};

}  // namespace builder

}  // namespace srv

template<typename MessageType>
auto build();

template<>
inline
auto build<::rrm_msgs::srv::Command_Response>()
{
  return rrm_msgs::srv::builder::Init_Command_Response_result_code();
}

}  // namespace rrm_msgs

#endif  // RRM_MSGS__SRV__DETAIL__COMMAND__BUILDER_HPP_
