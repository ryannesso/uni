// generated from rosidl_generator_c/resource/idl__functions.c.em
// with input from rrm_msgs:srv/Command.idl
// generated code does not contain a copyright notice
#include "rrm_msgs/srv/detail/command__functions.h"

#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "rcutils/allocator.h"

// Include directives for member types
// Member `positions`
// Member `velocities`
#include "rosidl_runtime_c/primitives_sequence_functions.h"

bool
rrm_msgs__srv__Command_Request__init(rrm_msgs__srv__Command_Request * msg)
{
  if (!msg) {
    return false;
  }
  // positions
  if (!rosidl_runtime_c__double__Sequence__init(&msg->positions, 0)) {
    rrm_msgs__srv__Command_Request__fini(msg);
    return false;
  }
  // velocities
  if (!rosidl_runtime_c__double__Sequence__init(&msg->velocities, 0)) {
    rrm_msgs__srv__Command_Request__fini(msg);
    return false;
  }
  return true;
}

void
rrm_msgs__srv__Command_Request__fini(rrm_msgs__srv__Command_Request * msg)
{
  if (!msg) {
    return;
  }
  // positions
  rosidl_runtime_c__double__Sequence__fini(&msg->positions);
  // velocities
  rosidl_runtime_c__double__Sequence__fini(&msg->velocities);
}

bool
rrm_msgs__srv__Command_Request__are_equal(const rrm_msgs__srv__Command_Request * lhs, const rrm_msgs__srv__Command_Request * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  // positions
  if (!rosidl_runtime_c__double__Sequence__are_equal(
      &(lhs->positions), &(rhs->positions)))
  {
    return false;
  }
  // velocities
  if (!rosidl_runtime_c__double__Sequence__are_equal(
      &(lhs->velocities), &(rhs->velocities)))
  {
    return false;
  }
  return true;
}

bool
rrm_msgs__srv__Command_Request__copy(
  const rrm_msgs__srv__Command_Request * input,
  rrm_msgs__srv__Command_Request * output)
{
  if (!input || !output) {
    return false;
  }
  // positions
  if (!rosidl_runtime_c__double__Sequence__copy(
      &(input->positions), &(output->positions)))
  {
    return false;
  }
  // velocities
  if (!rosidl_runtime_c__double__Sequence__copy(
      &(input->velocities), &(output->velocities)))
  {
    return false;
  }
  return true;
}

rrm_msgs__srv__Command_Request *
rrm_msgs__srv__Command_Request__create()
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  rrm_msgs__srv__Command_Request * msg = (rrm_msgs__srv__Command_Request *)allocator.allocate(sizeof(rrm_msgs__srv__Command_Request), allocator.state);
  if (!msg) {
    return NULL;
  }
  memset(msg, 0, sizeof(rrm_msgs__srv__Command_Request));
  bool success = rrm_msgs__srv__Command_Request__init(msg);
  if (!success) {
    allocator.deallocate(msg, allocator.state);
    return NULL;
  }
  return msg;
}

void
rrm_msgs__srv__Command_Request__destroy(rrm_msgs__srv__Command_Request * msg)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (msg) {
    rrm_msgs__srv__Command_Request__fini(msg);
  }
  allocator.deallocate(msg, allocator.state);
}


bool
rrm_msgs__srv__Command_Request__Sequence__init(rrm_msgs__srv__Command_Request__Sequence * array, size_t size)
{
  if (!array) {
    return false;
  }
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  rrm_msgs__srv__Command_Request * data = NULL;

  if (size) {
    data = (rrm_msgs__srv__Command_Request *)allocator.zero_allocate(size, sizeof(rrm_msgs__srv__Command_Request), allocator.state);
    if (!data) {
      return false;
    }
    // initialize all array elements
    size_t i;
    for (i = 0; i < size; ++i) {
      bool success = rrm_msgs__srv__Command_Request__init(&data[i]);
      if (!success) {
        break;
      }
    }
    if (i < size) {
      // if initialization failed finalize the already initialized array elements
      for (; i > 0; --i) {
        rrm_msgs__srv__Command_Request__fini(&data[i - 1]);
      }
      allocator.deallocate(data, allocator.state);
      return false;
    }
  }
  array->data = data;
  array->size = size;
  array->capacity = size;
  return true;
}

void
rrm_msgs__srv__Command_Request__Sequence__fini(rrm_msgs__srv__Command_Request__Sequence * array)
{
  if (!array) {
    return;
  }
  rcutils_allocator_t allocator = rcutils_get_default_allocator();

  if (array->data) {
    // ensure that data and capacity values are consistent
    assert(array->capacity > 0);
    // finalize all array elements
    for (size_t i = 0; i < array->capacity; ++i) {
      rrm_msgs__srv__Command_Request__fini(&array->data[i]);
    }
    allocator.deallocate(array->data, allocator.state);
    array->data = NULL;
    array->size = 0;
    array->capacity = 0;
  } else {
    // ensure that data, size, and capacity values are consistent
    assert(0 == array->size);
    assert(0 == array->capacity);
  }
}

rrm_msgs__srv__Command_Request__Sequence *
rrm_msgs__srv__Command_Request__Sequence__create(size_t size)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  rrm_msgs__srv__Command_Request__Sequence * array = (rrm_msgs__srv__Command_Request__Sequence *)allocator.allocate(sizeof(rrm_msgs__srv__Command_Request__Sequence), allocator.state);
  if (!array) {
    return NULL;
  }
  bool success = rrm_msgs__srv__Command_Request__Sequence__init(array, size);
  if (!success) {
    allocator.deallocate(array, allocator.state);
    return NULL;
  }
  return array;
}

void
rrm_msgs__srv__Command_Request__Sequence__destroy(rrm_msgs__srv__Command_Request__Sequence * array)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (array) {
    rrm_msgs__srv__Command_Request__Sequence__fini(array);
  }
  allocator.deallocate(array, allocator.state);
}

bool
rrm_msgs__srv__Command_Request__Sequence__are_equal(const rrm_msgs__srv__Command_Request__Sequence * lhs, const rrm_msgs__srv__Command_Request__Sequence * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  if (lhs->size != rhs->size) {
    return false;
  }
  for (size_t i = 0; i < lhs->size; ++i) {
    if (!rrm_msgs__srv__Command_Request__are_equal(&(lhs->data[i]), &(rhs->data[i]))) {
      return false;
    }
  }
  return true;
}

bool
rrm_msgs__srv__Command_Request__Sequence__copy(
  const rrm_msgs__srv__Command_Request__Sequence * input,
  rrm_msgs__srv__Command_Request__Sequence * output)
{
  if (!input || !output) {
    return false;
  }
  if (output->capacity < input->size) {
    const size_t allocation_size =
      input->size * sizeof(rrm_msgs__srv__Command_Request);
    rcutils_allocator_t allocator = rcutils_get_default_allocator();
    rrm_msgs__srv__Command_Request * data =
      (rrm_msgs__srv__Command_Request *)allocator.reallocate(
      output->data, allocation_size, allocator.state);
    if (!data) {
      return false;
    }
    // If reallocation succeeded, memory may or may not have been moved
    // to fulfill the allocation request, invalidating output->data.
    output->data = data;
    for (size_t i = output->capacity; i < input->size; ++i) {
      if (!rrm_msgs__srv__Command_Request__init(&output->data[i])) {
        // If initialization of any new item fails, roll back
        // all previously initialized items. Existing items
        // in output are to be left unmodified.
        for (; i-- > output->capacity; ) {
          rrm_msgs__srv__Command_Request__fini(&output->data[i]);
        }
        return false;
      }
    }
    output->capacity = input->size;
  }
  output->size = input->size;
  for (size_t i = 0; i < input->size; ++i) {
    if (!rrm_msgs__srv__Command_Request__copy(
        &(input->data[i]), &(output->data[i])))
    {
      return false;
    }
  }
  return true;
}


// Include directives for member types
// Member `message`
#include "rosidl_runtime_c/string_functions.h"

bool
rrm_msgs__srv__Command_Response__init(rrm_msgs__srv__Command_Response * msg)
{
  if (!msg) {
    return false;
  }
  // result_code
  // message
  if (!rosidl_runtime_c__String__init(&msg->message)) {
    rrm_msgs__srv__Command_Response__fini(msg);
    return false;
  }
  return true;
}

void
rrm_msgs__srv__Command_Response__fini(rrm_msgs__srv__Command_Response * msg)
{
  if (!msg) {
    return;
  }
  // result_code
  // message
  rosidl_runtime_c__String__fini(&msg->message);
}

bool
rrm_msgs__srv__Command_Response__are_equal(const rrm_msgs__srv__Command_Response * lhs, const rrm_msgs__srv__Command_Response * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  // result_code
  if (lhs->result_code != rhs->result_code) {
    return false;
  }
  // message
  if (!rosidl_runtime_c__String__are_equal(
      &(lhs->message), &(rhs->message)))
  {
    return false;
  }
  return true;
}

bool
rrm_msgs__srv__Command_Response__copy(
  const rrm_msgs__srv__Command_Response * input,
  rrm_msgs__srv__Command_Response * output)
{
  if (!input || !output) {
    return false;
  }
  // result_code
  output->result_code = input->result_code;
  // message
  if (!rosidl_runtime_c__String__copy(
      &(input->message), &(output->message)))
  {
    return false;
  }
  return true;
}

rrm_msgs__srv__Command_Response *
rrm_msgs__srv__Command_Response__create()
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  rrm_msgs__srv__Command_Response * msg = (rrm_msgs__srv__Command_Response *)allocator.allocate(sizeof(rrm_msgs__srv__Command_Response), allocator.state);
  if (!msg) {
    return NULL;
  }
  memset(msg, 0, sizeof(rrm_msgs__srv__Command_Response));
  bool success = rrm_msgs__srv__Command_Response__init(msg);
  if (!success) {
    allocator.deallocate(msg, allocator.state);
    return NULL;
  }
  return msg;
}

void
rrm_msgs__srv__Command_Response__destroy(rrm_msgs__srv__Command_Response * msg)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (msg) {
    rrm_msgs__srv__Command_Response__fini(msg);
  }
  allocator.deallocate(msg, allocator.state);
}


bool
rrm_msgs__srv__Command_Response__Sequence__init(rrm_msgs__srv__Command_Response__Sequence * array, size_t size)
{
  if (!array) {
    return false;
  }
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  rrm_msgs__srv__Command_Response * data = NULL;

  if (size) {
    data = (rrm_msgs__srv__Command_Response *)allocator.zero_allocate(size, sizeof(rrm_msgs__srv__Command_Response), allocator.state);
    if (!data) {
      return false;
    }
    // initialize all array elements
    size_t i;
    for (i = 0; i < size; ++i) {
      bool success = rrm_msgs__srv__Command_Response__init(&data[i]);
      if (!success) {
        break;
      }
    }
    if (i < size) {
      // if initialization failed finalize the already initialized array elements
      for (; i > 0; --i) {
        rrm_msgs__srv__Command_Response__fini(&data[i - 1]);
      }
      allocator.deallocate(data, allocator.state);
      return false;
    }
  }
  array->data = data;
  array->size = size;
  array->capacity = size;
  return true;
}

void
rrm_msgs__srv__Command_Response__Sequence__fini(rrm_msgs__srv__Command_Response__Sequence * array)
{
  if (!array) {
    return;
  }
  rcutils_allocator_t allocator = rcutils_get_default_allocator();

  if (array->data) {
    // ensure that data and capacity values are consistent
    assert(array->capacity > 0);
    // finalize all array elements
    for (size_t i = 0; i < array->capacity; ++i) {
      rrm_msgs__srv__Command_Response__fini(&array->data[i]);
    }
    allocator.deallocate(array->data, allocator.state);
    array->data = NULL;
    array->size = 0;
    array->capacity = 0;
  } else {
    // ensure that data, size, and capacity values are consistent
    assert(0 == array->size);
    assert(0 == array->capacity);
  }
}

rrm_msgs__srv__Command_Response__Sequence *
rrm_msgs__srv__Command_Response__Sequence__create(size_t size)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  rrm_msgs__srv__Command_Response__Sequence * array = (rrm_msgs__srv__Command_Response__Sequence *)allocator.allocate(sizeof(rrm_msgs__srv__Command_Response__Sequence), allocator.state);
  if (!array) {
    return NULL;
  }
  bool success = rrm_msgs__srv__Command_Response__Sequence__init(array, size);
  if (!success) {
    allocator.deallocate(array, allocator.state);
    return NULL;
  }
  return array;
}

void
rrm_msgs__srv__Command_Response__Sequence__destroy(rrm_msgs__srv__Command_Response__Sequence * array)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (array) {
    rrm_msgs__srv__Command_Response__Sequence__fini(array);
  }
  allocator.deallocate(array, allocator.state);
}

bool
rrm_msgs__srv__Command_Response__Sequence__are_equal(const rrm_msgs__srv__Command_Response__Sequence * lhs, const rrm_msgs__srv__Command_Response__Sequence * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  if (lhs->size != rhs->size) {
    return false;
  }
  for (size_t i = 0; i < lhs->size; ++i) {
    if (!rrm_msgs__srv__Command_Response__are_equal(&(lhs->data[i]), &(rhs->data[i]))) {
      return false;
    }
  }
  return true;
}

bool
rrm_msgs__srv__Command_Response__Sequence__copy(
  const rrm_msgs__srv__Command_Response__Sequence * input,
  rrm_msgs__srv__Command_Response__Sequence * output)
{
  if (!input || !output) {
    return false;
  }
  if (output->capacity < input->size) {
    const size_t allocation_size =
      input->size * sizeof(rrm_msgs__srv__Command_Response);
    rcutils_allocator_t allocator = rcutils_get_default_allocator();
    rrm_msgs__srv__Command_Response * data =
      (rrm_msgs__srv__Command_Response *)allocator.reallocate(
      output->data, allocation_size, allocator.state);
    if (!data) {
      return false;
    }
    // If reallocation succeeded, memory may or may not have been moved
    // to fulfill the allocation request, invalidating output->data.
    output->data = data;
    for (size_t i = output->capacity; i < input->size; ++i) {
      if (!rrm_msgs__srv__Command_Response__init(&output->data[i])) {
        // If initialization of any new item fails, roll back
        // all previously initialized items. Existing items
        // in output are to be left unmodified.
        for (; i-- > output->capacity; ) {
          rrm_msgs__srv__Command_Response__fini(&output->data[i]);
        }
        return false;
      }
    }
    output->capacity = input->size;
  }
  output->size = input->size;
  for (size_t i = 0; i < input->size; ++i) {
    if (!rrm_msgs__srv__Command_Response__copy(
        &(input->data[i]), &(output->data[i])))
    {
      return false;
    }
  }
  return true;
}
