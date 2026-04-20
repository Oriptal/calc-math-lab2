#include "Solvers.hpp"
#include <iostream>

#include <algorithm>
#include <cmath>
#include <limits>

double Solver::df(MathFunc f, double x) {
  const double h = 1e-6;
  return (f(x + h) - f(x - h)) / (2 * h);
}

double Solver::d2f(MathFunc f, double x) {
  const double h = 1e-4;
  return (f(x + h) - 2 * f(x) + f(x - h)) / (h * h);
}

std::pair<int, double> DihotomiaSolver::solve(MathFunc f, double a, double b) {
  double fa = f(a);
  double fb = f(b);
  int iter = 0;
  if (std::abs(fa) <= EPS) {
    return {0, a};
  }
  if (std::abs(fb) <= EPS) {
    return {0, b};
  }
  if (fa * fb > 0.0) {
    return {0, std::numeric_limits<double>::quiet_NaN()};
  }

  while ((b - a) > EPS) {
    iter++;
    const double x_0 = (a + b) / 2.0;
    const double fx = f(x_0);
    if (std::abs(fx) <= EPS) {
      return {iter, x_0};
    }
    if (fa * fx <= 0.0) {
      b = x_0;
      fb = fx;
    } else {
      a = x_0;
      fa = fx;
    }
  }
  return {iter, (a + b) / 2.0};
}

std::pair<int, double> IterSolver::solve(MathFunc f, double a, double b) {
  constexpr int samples = 1000;
  double maxDf = 0.0;
  for (int i = 0; i <= samples; ++i) {
    const double x = a + (b - a) * static_cast<double>(i) / samples;
    maxDf = std::max(maxDf, std::abs(df(f, x)));
  }

  if (!std::isfinite(maxDf)) {
    return {0, std::numeric_limits<double>::quiet_NaN()};
  }

  const double mid = (a + b) / 2.0;
  const double dmid = df(f, mid);
  const double lambda = (dmid >= 0.0 ? -1.0 : 1.0) / maxDf;

  double q = 0.0;
  for (int i = 0; i <= samples; ++i) {
    const double x = a + (b - a) * static_cast<double>(i) / samples;
    q = std::max(q, std::abs(1.0 + lambda * df(f, x)));
  }
  if (q >= 1.0 || !std::isfinite(q)) {
    return {0, std::numeric_limits<double>::quiet_NaN()};
  }

  double x = a;
  if (f(x) * d2f(f, x) < 0.0) {
    x = b;
  }

  double xn = lambda * f(x) + x;
  int iter = 0;
  while (std::abs(xn - x) > EPS) {
    x = xn;
    xn = lambda * f(x) + x;
    if (!std::isfinite(xn)) {
      return {iter, std::numeric_limits<double>::quiet_NaN()};
    }
    iter++;
  }

  return {iter, xn};
}

std::pair<int, double> NewtonSolver::solve(MathFunc f, double a, double b) {
  double x = a;
  if (f(x) * d2f(f, x) < 0.0) {
    x = b;
  }

  int iter = 0;
  while (std::abs(f(x)) > EPS) {
    const double dfx = df(f, x);
    if (std::abs(dfx) <= 1e-12) {
      return {iter, std::numeric_limits<double>::quiet_NaN()};
    }
    x = x - f(x) / dfx;
    if (!std::isfinite(x)) {
      return {iter, std::numeric_limits<double>::quiet_NaN()};
    }
    iter++;
  }

  return {iter, x};
}

double SystemIterSolver::dfdx(SystemFunc f, double x, double y) {
  const double h = 1e-6;
  return (f(x + h, y) - f(x - h, y)) / (2 * h);
}

double SystemIterSolver::dfdy(SystemFunc f, double x, double y) {
  const double h = 1e-6;
  return (f(x, y + h) - f(x, y - h)) / (2 * h);
}

std::pair<std::pair<int, double>, std::pair<int, double>>
SystemIterSolver::solve(SystemFunc phiX, SystemFunc phiY, double x0,
                        double y0) const {
  double x = x0;
  double y = y0;

  for (int iter = 0; iter < SystemIterSolver::kMaxIterations; ++iter) {
    const double q1 = std::abs(dfdx(phiX, x, y)) + std::abs(dfdy(phiX, x, y));
    const double q2 = std::abs(dfdx(phiY, x, y)) + std::abs(dfdy(phiY, x, y));
    const double q = std::max(q1, q2);
    if (!std::isfinite(q) || q >= 1.0) {
      return {{iter, std::numeric_limits<double>::quiet_NaN()},
              {iter, std::numeric_limits<double>::quiet_NaN()}};
    }

    const double nextX = phiX(x, y);
    const double nextY = phiY(x, y);
    if (!std::isfinite(nextX) || !std::isfinite(nextY)) {
      return {{iter, std::numeric_limits<double>::quiet_NaN()},
              {iter, std::numeric_limits<double>::quiet_NaN()}};
    }

    if (std::max(std::abs(nextX - x), std::abs(nextY - y)) <= EPS) {
      return {{iter, nextX}, {iter, nextY}};
    }

    x = nextX;
    y = nextY;

    // std::cout << x << " " << y << "\n";
  }

  return {{0, std::numeric_limits<double>::quiet_NaN()},
          {0, std::numeric_limits<double>::quiet_NaN()}};
}
