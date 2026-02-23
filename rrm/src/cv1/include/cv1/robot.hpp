class Robot {
public:
  Robot();
  void move(double x, double y);
  double getX() const { return x_; }
  double getY() const { return y_; }

private:
  double x_;
  double y_;
};