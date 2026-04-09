#include "Solvers.hpp"

#include <cmath>
#include <limits>

namespace {
constexpr int kMaxIterations = 100000;
}

double Solver::df(MathFunc f, double x) {
  const double h = 1e-6;
  return (f(x + h) - f(x - h)) / (2 * h);
}

double Solver::d2f(MathFunc f, double x) {
  const double h = 1e-4;
  return (f(x + h) - 2 * f(x) + f(x - h)) / (h * h);
}

double DihotomiaSolver::solve(MathFunc f, double a, double b) {
  double fa = f(a);
  double fb = f(b);
  if (std::abs(fa) <= EPS) {
    return a;
  }
  if (std::abs(fb) <= EPS) {
    return b;
  }
  if (fa * fb > 0.0) {
    return std::numeric_limits<double>::quiet_NaN();
  }

  int iter = 0;
  while ((b - a) > EPS && iter < kMaxIterations) {
    const double x_0 = (a + b) / 2.0;
    const double fx = f(x_0);
    if (std::abs(fx) <= EPS) {
      return x_0;
    }
    if (fa * fx <= 0.0) {
      b = x_0;
      fb = fx;
    } else {
      a = x_0;
      fa = fx;
    }
    iter++;
  }
  return (a + b) / 2.0;
}

double IterSolver::solve(MathFunc f, double a, double b) {
  constexpr int samples = 1000;
  double maxDf = 0.0;
  for (int i = 0; i <= samples; ++i) {
    const double x = a + (b - a) * static_cast<double>(i) / samples;
    maxDf = std::max(maxDf, std::abs(df(f, x)));
  }

  if (maxDf <= 1e-12 || !std::isfinite(maxDf)) {
    return std::numeric_limits<double>::quiet_NaN();
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
    return std::numeric_limits<double>::quiet_NaN();
  }

  double x = a;
  if (f(x) * d2f(f, x) < 0.0) {
    x = b;
  }

  double xn = lambda * f(x) + x;
  int iter = 0;
  while (std::abs(xn - x) > EPS && iter < kMaxIterations) {
    x = xn;
    xn = lambda * f(x) + x;
    if (!std::isfinite(xn)) {
      return std::numeric_limits<double>::quiet_NaN();
    }
    iter++;
  }

  return xn;
}

double NewtonSolver::solve(MathFunc f, double a, double b) {
  double x = a;
  if (f(x) * d2f(f, x) < 0.0) {
    x = b;
  }

  int iter = 0;
  while (std::abs(f(x)) > EPS && iter < kMaxIterations) {
    const double dfx = df(f, x);
    if (std::abs(dfx) <= 1e-12) {
      return std::numeric_limits<double>::quiet_NaN();
    }
    x = x - f(x) / dfx;
    if (!std::isfinite(x)) {
      return std::numeric_limits<double>::quiet_NaN();
    }
    iter++;
  }

  return x;
}
