#include "cv1/robot.hpp"
#include "rclcpp/rclcpp.hpp"
#include <termios.h>
#include <unistd.h>

int getch() {
  struct termios oldattr, newattr;
  int ch;
  tcgetattr(STDIN_FILENO, &oldattr);
  newattr = oldattr;
  newattr.c_lflag &= ~(ICANON | ECHO);
  tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
  ch = getchar();
  tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
  return ch;
} // website https://ascheng.medium.com/linux-getch-for-unix-c2c829721a30

int main(int argc, char **argv) {
  rclcpp::init(argc, argv);
  int flag = 1;
  char ch;

  Robot robot;
  RCLCPP_INFO(rclcpp::get_logger("rclcpp"), "position: %f %f", robot.getX(),
              robot.getY());
  while (flag) {
    ch = getch();
    if (ch == 'w') {
      robot.move(0.0, 0.1);
    } else if (ch == 's') {
      robot.move(0.0, -0.1);
    } else if (ch == 'a') {
      robot.move(-0.1, 0.0);
    } else if (ch == 'd') {
      robot.move(0.1, 0.0);
    } else if (ch == 'q') {
      flag = 0;
    }
    RCLCPP_INFO(rclcpp::get_logger("rclcpp"), "position: %f %f", robot.getX(),
                robot.getY());
  }
  return 0;
}