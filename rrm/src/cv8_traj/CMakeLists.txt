cmake_minimum_required(VERSION 3.8)
project(cv8_traj)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(std_srvs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(interactive_markers REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(abb_irb4600_ikfast REQUIRED)

add_library(${PROJECT_NAME}_manipulator src/manipulator.cpp)
target_include_directories(${PROJECT_NAME}_manipulator PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)
target_link_libraries(${PROJECT_NAME}_manipulator Eigen3::Eigen)

add_executable(model_spawner src/model_spawner.cpp)
ament_target_dependencies(model_spawner rclcpp visualization_msgs)

add_executable(pose_teacher src/pose_teacher.cpp)
ament_target_dependencies(pose_teacher rclcpp sensor_msgs geometry_msgs visualization_msgs interactive_markers abb_irb4600_ikfast)
target_link_libraries(pose_teacher Eigen3::Eigen)

add_executable(manipulator_node src/manipulator_node.cpp)
ament_target_dependencies(manipulator_node rclcpp std_msgs std_srvs sensor_msgs geometry_msgs visualization_msgs abb_irb4600_ikfast)
target_link_libraries(manipulator_node ${PROJECT_NAME}_manipulator Eigen3::Eigen)

install(TARGETS
  ${PROJECT_NAME}_manipulator
  model_spawner
  pose_teacher
  manipulator_node
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib/${PROJECT_NAME}
)

install(DIRECTORY include/
  DESTINATION include
)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
