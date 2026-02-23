// generated from rosidl_generator_cpp/resource/idl__struct.hpp.em
// with input from rrm_msgs:msg/Command.idl
// generated code does not contain a copyright notice

#ifndef RRM_MSGS__MSG__DETAIL__COMMAND__STRUCT_HPP_
#define RRM_MSGS__MSG__DETAIL__COMMAND__STRUCT_HPP_

#include <algorithm>
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "rosidl_runtime_cpp/bounded_vector.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


#ifndef _WIN32
# define DEPRECATED__rrm_msgs__msg__Command __attribute__((deprecated))
#else
# define DEPRECATED__rrm_msgs__msg__Command __declspec(deprecated)
#endif

namespace rrm_msgs
{

namespace msg
{

// message struct
template<class ContainerAllocator>
struct Command_
{
  using Type = Command_<ContainerAllocator>;

  explicit Command_(rosidl_runtime_cpp::MessageInitialization _init = rosidl_runtime_cpp::MessageInitialization::ALL)
  {
    if (rosidl_runtime_cpp::MessageInitialization::ALL == _init ||
      rosidl_runtime_cpp::MessageInitialization::ZERO == _init)
    {
      this->joint_id = 0l;
      this->position = 0.0;
    }
  }

  explicit Command_(const ContainerAllocator & _alloc, rosidl_runtime_cpp::MessageInitialization _init = rosidl_runtime_cpp::MessageInitialization::ALL)
  {
    (void)_alloc;
    if (rosidl_runtime_cpp::MessageInitialization::ALL == _init ||
      rosidl_runtime_cpp::MessageInitialization::ZERO == _init)
    {
      this->joint_id = 0l;
      this->position = 0.0;
    }
  }

  // field types and members
  using _joint_id_type =
    int32_t;
  _joint_id_type joint_id;
  using _position_type =
    double;
  _position_type position;

  // setters for named parameter idiom
  Type & set__joint_id(
    const int32_t & _arg)
  {
    this->joint_id = _arg;
    return *this;
  }
  Type & set__position(
    const double & _arg)
  {
    this->position = _arg;
    return *this;
  }

  // constant declarations

  // pointer types
  using RawPtr =
    rrm_msgs::msg::Command_<ContainerAllocator> *;
  using ConstRawPtr =
    const rrm_msgs::msg::Command_<ContainerAllocator> *;
  using SharedPtr =
    std::shared_ptr<rrm_msgs::msg::Command_<ContainerAllocator>>;
  using ConstSharedPtr =
    std::shared_ptr<rrm_msgs::msg::Command_<ContainerAllocator> const>;

  template<typename Deleter = std::default_delete<
      rrm_msgs::msg::Command_<ContainerAllocator>>>
  using UniquePtrWithDeleter =
    std::unique_ptr<rrm_msgs::msg::Command_<ContainerAllocator>, Deleter>;

  using UniquePtr = UniquePtrWithDeleter<>;

  template<typename Deleter = std::default_delete<
      rrm_msgs::msg::Command_<ContainerAllocator>>>
  using ConstUniquePtrWithDeleter =
    std::unique_ptr<rrm_msgs::msg::Command_<ContainerAllocator> const, Deleter>;
  using ConstUniquePtr = ConstUniquePtrWithDeleter<>;

  using WeakPtr =
    std::weak_ptr<rrm_msgs::msg::Command_<ContainerAllocator>>;
  using ConstWeakPtr =
    std::weak_ptr<rrm_msgs::msg::Command_<ContainerAllocator> const>;

  // pointer types similar to ROS 1, use SharedPtr / ConstSharedPtr instead
  // NOTE: Can't use 'using' here because GNU C++ can't parse attributes properly
  typedef DEPRECATED__rrm_msgs__msg__Command
    std::shared_ptr<rrm_msgs::msg::Command_<ContainerAllocator>>
    Ptr;
  typedef DEPRECATED__rrm_msgs__msg__Command
    std::shared_ptr<rrm_msgs::msg::Command_<ContainerAllocator> const>
    ConstPtr;

  // comparison operators
  bool operator==(const Command_ & other) const
  {
    if (this->joint_id != other.joint_id) {
      return false;
    }
    if (this->position != other.position) {
      return false;
    }
    return true;
  }
  bool operator!=(const Command_ & other) const
  {
    return !this->operator==(other);
  }
};  // struct Command_

// alias to use template instance with default allocator
using Command =
  rrm_msgs::msg::Command_<std::allocator<void>>;

// constant definitions

}  // namespace msg

}  // namespace rrm_msgs

#endif  // RRM_MSGS__MSG__DETAIL__COMMAND__STRUCT_HPP_
