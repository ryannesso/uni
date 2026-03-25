cmake_minimum_required(VERSION 3.5)
project(cv6)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(rrm_msgs REQUIRED)
find_package(urdf REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(Eigen3 REQUIRED)

# 1. Генерация сервисов
rosidl_generate_interfaces(${PROJECT_NAME}
  "srv/ComputeIK.srv"
  "srv/BestIK.srv"
  "srv/MoveToCartesian.srv"
)

# 1.5 Добавляем директорию include, чтобы компилятор нашел cv6/logger_node.hpp
include_directories(include)

# 2. Узел logger_node (он же JointLogger)
add_executable(logger_node src/joint_logger.cpp)
ament_target_dependencies(logger_node rclcpp sensor_msgs tf2_ros geometry_msgs)
target_link_libraries(logger_node Eigen3::Eigen)

# 3. Узел ik_solver
add_executable(ik_solver src/ik_solver.cpp)
ament_target_dependencies(ik_solver rclcpp sensor_msgs geometry_msgs tf2_ros rrm_msgs urdf)
target_link_libraries(ik_solver Eigen3::Eigen)
# Исправление Deprecation Warning:
rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} "rosidl_typesupport_cpp")
target_link_libraries(ik_solver "${cpp_typesupport_target}")

# 4. Узел motion_manager
add_executable(motion_manager src/motion_manager.cpp)
ament_target_dependencies(motion_manager rclcpp sensor_msgs rrm_msgs)
target_link_libraries(motion_manager "${cpp_typesupport_target}")

# 5. Узел teleop (взято из вашего исходного кода)
add_executable(cv6_node src/teleop.cpp)
ament_target_dependencies(cv6_node rclcpp sensor_msgs rrm_msgs)

install(TARGETS logger_node ik_solver motion_manager cv6_node
  RUNTIME DESTINATION lib/${PROJECT_NAME})

# Указываем CMake скопировать папки launch и config в собранный пакет
install(DIRECTORY
  launch
  config
  DESTINATION share/${PROJECT_NAME}
)

ament_export_dependencies(rosidl_default_runtime)
ament_package()
