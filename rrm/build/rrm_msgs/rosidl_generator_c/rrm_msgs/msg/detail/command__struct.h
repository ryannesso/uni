// generated from rosidl_generator_c/resource/idl__struct.h.em
// with input from rrm_msgs:msg/Command.idl
// generated code does not contain a copyright notice

#ifndef RRM_MSGS__MSG__DETAIL__COMMAND__STRUCT_H_
#define RRM_MSGS__MSG__DETAIL__COMMAND__STRUCT_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


// Constants defined in the message

/// Struct defined in msg/Command in the package rrm_msgs.
typedef struct rrm_msgs__msg__Command
{
  int32_t joint_id;
  double position;
} rrm_msgs__msg__Command;

// Struct for a sequence of rrm_msgs__msg__Command.
typedef struct rrm_msgs__msg__Command__Sequence
{
  rrm_msgs__msg__Command * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} rrm_msgs__msg__Command__Sequence;

#ifdef __cplusplus
}
#endif

#endif  // RRM_MSGS__MSG__DETAIL__COMMAND__STRUCT_H_
