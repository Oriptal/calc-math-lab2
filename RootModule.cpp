#include "RootModule.hpp"

#include "BackendUtil.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>

bool RootModule::selectEquation(qint32 equation, MathFunc &f) {
  switch (equation) {
  case 0:
    f = [](double x) { return x * x * x - x * x - 3 * x + 1; };
    return true;
  case 1:
    f = [](double x) { return std::cos(x) - std::exp(x); };
    return true;
  case 2:
    f = [](double x) {
      return x * x * x * x * x + 3 * x * x * x * x - 5 * x * x - 3 * x + 2;
    };
    return true;
  case 3:
    f = [](double x) { return 3 * x * x - 3; };
    return true;
  default:
    return false;
  }
}

QVariantMap RootModule::processData(qint32 method, qint32 equation,
                                    const QVariantMap &map) {
  QVariantMap result;

  MathFunc f;
  if (!selectEquation(equation, f)) {
    result.insert("status", static_cast<qint32>(INCORRECT_BORDERS));
    result.insert("value", std::numeric_limits<qreal>::quiet_NaN());
    return result;
  }

  bool okLeft = false;
  bool okRight = false;
  bool okEps = false;

  const double left =
      parseDouble(map.value("left", QString()).toString(), &okLeft);
  const double right =
      parseDouble(map.value("right", QString()).toString(), &okRight);
  const double eps =
      parseDouble(map.value("eps", QString()).toString(), &okEps);

  if (!okEps) {
    result.insert("status", static_cast<qint32>(INCORRECT_EPS));
    result.insert("value", std::numeric_limits<qreal>::quiet_NaN());
    return result;
  }
  if (!okLeft || !okRight) {
    result.insert("status", static_cast<qint32>(INCORRECT_BORDERS));
    result.insert("value", std::numeric_limits<qreal>::quiet_NaN());
    return result;
  }

  const Status status = Solver::validate(f, left, right, eps);
  if (status != SUCCESS) {
    result.insert("status", static_cast<qint32>(status));
    result.insert("value", std::numeric_limits<qreal>::quiet_NaN());
    return result;
  }

  int iter = 0;
  double value = std::numeric_limits<qreal>::quiet_NaN();
  switch (method) {
  case 0: {
    DihotomiaSolver solver(eps);
    auto pr = solver.solve(f, left, right);
    iter = pr.first;
    value = pr.second;
    break;
  }
  case 1: {
    NewtonSolver solver(eps);
    auto pr = solver.solve(f, left, right);
    iter = pr.first;
    value = pr.second;
    break;
  }
  case 2: {
    IterSolver solver(eps);
    auto pr = solver.solve(f, left, right);
    iter = pr.first;
    value = pr.second;
    break;
  }
  default:
    result.insert("status", static_cast<qint32>(INCORRECT_BORDERS));
    result.insert("value", std::numeric_limits<qreal>::quiet_NaN());
    return result;
  }

  if (!std::isfinite(value)) {
    result.insert("status", static_cast<qint32>(METHOD_DIVERGENCE));
    result.insert("value", std::numeric_limits<qreal>::quiet_NaN());
    return result;
  }

  result.insert("status", static_cast<qint32>(SUCCESS));
  result.insert("value", value);
  result.insert("iter", iter);
  std::cout << SUCCESS << " " << value << " " << iter;
  return result;
}

QVariantList RootModule::sampleCurve(qint32 equation, qreal left, qreal right,
                                     qint32 points) {
  QVariantList result;
  MathFunc f;
  if (!selectEquation(equation, f)) {
    return result;
  }

  if (!std::isfinite(left) || !std::isfinite(right) || !(left < right)) {
    left = -5.0;
    right = 5.0;
  }

  const int safePoints = std::clamp(static_cast<int>(points), 20, 3000);
  const double step = (right - left) / static_cast<double>(safePoints - 1);

  for (int i = 0; i < safePoints; ++i) {
    const double x = left + i * step;
    const double y = f(x);
    if (!std::isfinite(y)) {
      continue;
    }

    QVariantMap point;
    point.insert("x", x);
    point.insert("y", y);
    result.push_back(point);
  }

  return result;
}
