from launch import LaunchDescription
from launch_ros.actions import Node
from launch.substitutions import Command, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    abb_model_share = FindPackageShare('abb_model')
    cv8_traj_share = FindPackageShare('cv8_traj')

    robot_description = Command([
        'xacro ',
        PathJoinSubstitution([abb_model_share, 'urdf', 'abb_irb4600_60_205.xacro'])
    ])

    return LaunchDescription([
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            name='robot_state_publisher',
            output='screen',
            parameters=[{'robot_description': robot_description}],
        ),

        Node(
            package='cv8_traj',
            executable='model_spawner',
            name='model_spawner',
            output='screen',
        ),

        Node(
            package='cv8_traj',
            executable='pose_teacher',
            name='pose_teacher',
            output='screen',
        ),

        Node(
            package='cv8_traj',
            executable='manipulator_node',
            name='manipulator_node',
            output='screen',
            parameters=[PathJoinSubstitution([cv8_traj_share, 'config', 'params.yaml'])],
        ),

        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            output='screen',
        ),
    ])
