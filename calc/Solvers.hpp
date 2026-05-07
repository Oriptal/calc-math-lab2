#pragma once

#include <cmath>
#include <functional>
#include <utility>

using MathFunc = std::function<double(double)>;
using SystemFunc = std::function<double(double, double)>;

enum Status {
  SUCCESS = 0,
  INCORRECT_BORDERS = 1,
  SEVERAL_ROOTS = 2,
  NO_ROOTS = 3,
  INCORRECT_EPS = 4,
  METHOD_DIVERGENCE = 5
};

class Solver {
protected:
  double EPS;

public:
  Solver(double EPS) : EPS(EPS) {};
  virtual ~Solver() = default;
  virtual std::pair<int, double> solve(MathFunc f, double a, double b) = 0;

  static Status validate(MathFunc f, double a, double b, double EPS) {
    if (!(EPS > 0.0) || !std::isfinite(EPS)) {
      return INCORRECT_EPS;
    }

    constexpr int samples = 2000;
    const double step = (b - a) / samples;
    const double zeroTol = 1e-10;

    double prev = f(a);
    if (!std::isfinite(prev)) {
      return INCORRECT_BORDERS;
    }

    int rootCounter = 0;
    bool prevNearZero = std::abs(prev) <= zeroTol;
    if (prevNearZero) {
      rootCounter++;
    }

    for (int i = 1; i <= samples; ++i) {
      const double x = a + i * step;
      const double cur = f(x);
      if (!std::isfinite(cur)) {
        return INCORRECT_BORDERS;
      }

      const bool curNearZero = std::abs(cur) <= zeroTol;
      if ((prev < 0.0 && cur > 0.0) || (prev > 0.0 && cur < 0.0)) {
        rootCounter++;
      } else if (curNearZero && !prevNearZero) {
        rootCounter++;
      }

      prev = cur;
      prevNearZero = curNearZero;
    }

    if (rootCounter == 0) {
      return NO_ROOTS;
    }
    if (rootCounter == 1) {
      return SUCCESS;
    }
    return SEVERAL_ROOTS;
  }

  double df(MathFunc f, double x);
  double d2f(MathFunc f, double x);
};

class DihotomiaSolver : public Solver {
public:
  DihotomiaSolver(double EPS) : Solver(EPS) {};
  std::pair<int, double> solve(MathFunc f, double a, double b) override;
};

class NewtonSolver : public Solver {
public:
  NewtonSolver(double EPS) : Solver(EPS) {};
  std::pair<int, double> solve(MathFunc f, double a, double b) override;
};

class IterSolver : public Solver {
public:
  IterSolver(double EPS) : Solver(EPS) {};
  std::pair<int, double> solve(MathFunc f, double a, double b) override;
};

class SystemIterSolver {
  double EPS;
  static constexpr int kMaxIterations = 10'000;

public:
  explicit SystemIterSolver(double EPS) : EPS(EPS) {}

  std::pair<std::pair<int, double>, std::pair<int, double>>
  solve(SystemFunc phiX, SystemFunc phiY, double x0, double y0) const;

private:
  static double dfdx(SystemFunc f, double x, double y);
  static double dfdy(SystemFunc f, double x, double y);
};
