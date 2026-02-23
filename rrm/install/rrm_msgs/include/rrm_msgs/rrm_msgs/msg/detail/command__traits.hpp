// generated from rosidl_generator_cpp/resource/idl__traits.hpp.em
// with input from rrm_msgs:msg/Command.idl
// generated code does not contain a copyright notice

#ifndef RRM_MSGS__MSG__DETAIL__COMMAND__TRAITS_HPP_
#define RRM_MSGS__MSG__DETAIL__COMMAND__TRAITS_HPP_

#include <stdint.h>

#include <sstream>
#include <string>
#include <type_traits>

#include "rrm_msgs/msg/detail/command__struct.hpp"
#include "rosidl_runtime_cpp/traits.hpp"

namespace rrm_msgs
{

namespace msg
{

inline void to_flow_style_yaml(
  const Command & msg,
  std::ostream & out)
{
  out << "{";
  // member: joint_id
  {
    out << "joint_id: ";
    rosidl_generator_traits::value_to_yaml(msg.joint_id, out);
    out << ", ";
  }

  // member: position
  {
    out << "position: ";
    rosidl_generator_traits::value_to_yaml(msg.position, out);
  }
  out << "}";
}  // NOLINT(readability/fn_size)

inline void to_block_style_yaml(
  const Command & msg,
  std::ostream & out, size_t indentation = 0)
{
  // member: joint_id
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "joint_id: ";
    rosidl_generator_traits::value_to_yaml(msg.joint_id, out);
    out << "\n";
  }

  // member: position
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "position: ";
    rosidl_generator_traits::value_to_yaml(msg.position, out);
    out << "\n";
  }
}  // NOLINT(readability/fn_size)

inline std::string to_yaml(const Command & msg, bool use_flow_style = false)
{
  std::ostringstream out;
  if (use_flow_style) {
    to_flow_style_yaml(msg, out);
  } else {
    to_block_style_yaml(msg, out);
  }
  return out.str();
}

}  // namespace msg

}  // namespace rrm_msgs

namespace rosidl_generator_traits
{

[[deprecated("use rrm_msgs::msg::to_block_style_yaml() instead")]]
inline void to_yaml(
  const rrm_msgs::msg::Command & msg,
  std::ostream & out, size_t indentation = 0)
{
  rrm_msgs::msg::to_block_style_yaml(msg, out, indentation);
}

[[deprecated("use rrm_msgs::msg::to_yaml() instead")]]
inline std::string to_yaml(const rrm_msgs::msg::Command & msg)
{
  return rrm_msgs::msg::to_yaml(msg);
}

template<>
inline const char * data_type<rrm_msgs::msg::Command>()
{
  return "rrm_msgs::msg::Command";
}

template<>
inline const char * name<rrm_msgs::msg::Command>()
{
  return "rrm_msgs/msg/Command";
}

template<>
struct has_fixed_size<rrm_msgs::msg::Command>
  : std::integral_constant<bool, true> {};

template<>
struct has_bounded_size<rrm_msgs::msg::Command>
  : std::integral_constant<bool, true> {};

template<>
struct is_message<rrm_msgs::msg::Command>
  : std::true_type {};

}  // namespace rosidl_generator_traits

#endif  // RRM_MSGS__MSG__DETAIL__COMMAND__TRAITS_HPP_
