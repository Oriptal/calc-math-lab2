#include "Solvers.hpp"
#include <cmath>

double Solver::df(MathFunc f, double x) {
  double h = 1e-6;
  return (f(x + h) - f(x - h)) / (2 * h);
}

double Solver::d2f(MathFunc f, double x) {
  double h = 1e-4;
  return (f(x + h) - 2 * f(x) + f(x - h)) / (h * h);
}

double DihotomiaSolver::solve(MathFunc f, double a, double b) {
  while (b - a > EPS) {
    double x_0 = (a + b) / 2;
    if (f(x_0) * f(a) < 0) {
      b = x_0;
    } else {
      a = x_0;
    }
  }
  return (a + b) / 2;
}

double IterSolver::solve(MathFunc f, double a, double b) {
  double max_df = std::max(std::abs(df(f, a)), std::abs(df(f, b)));
  double lyambda = (double)1 / max_df;
  if (df(f, a) > 0) {
    lyambda *= -1;
  }
  double x = a;
  if (f(x) * d2f(f, x) < 0) {
    x = b;
  }
  double xn = lyambda * f(x) + x;
  while (std::abs(xn - x) > EPS) {
    x = xn;
    xn = lyambda * f(x) + x;
  }
  return xn;
}

double NewtonSolver::solve(MathFunc f, double a, double b) {
  double x = a;
  if (f(x) * d2f(f, x) < 0) {
    x = b;
  }

  while (std::abs(f(x)) > EPS) {
    x = x - f(x) / df(f, x);
  }
  return x;
}
