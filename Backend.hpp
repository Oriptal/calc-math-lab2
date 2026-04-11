#ifndef BACKEND_H
#define BACKEND_H

#include "calc/Solvers.hpp"

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

#include <algorithm>
#include <cmath>
#include <limits>

class Backend : public QObject {
  Q_OBJECT

public:
  explicit Backend(QObject *parent = nullptr) : QObject(parent) {}

  Q_INVOKABLE QVariantMap processData(qint32 method, qint32 equation,
                                      const QVariantMap &map) const {
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

    const QString leftText = map.value("left", QString()).toString();
    const QString rightText = map.value("right", QString()).toString();
    const QString epsText = map.value("eps", QString()).toString();

    const double left = parseDouble(leftText, &okLeft);
    const double right = parseDouble(rightText, &okRight);
    const double eps = parseDouble(epsText, &okEps);

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

    double value = std::numeric_limits<qreal>::quiet_NaN();
    switch (method) {
    case 0: {
      DihotomiaSolver solver(eps);
      value = solver.solve(f, left, right);
      break;
    }
    case 1: {
      NewtonSolver solver(eps);
      value = solver.solve(f, left, right);
      break;
    }
    case 2: {
      IterSolver solver(eps);
      value = solver.solve(f, left, right);
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
    return result;
  }

  Q_INVOKABLE QVariantList sampleCurve(qint32 equation, qreal left, qreal right,
                                       qint32 points) const {
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

private:
  static double parseDouble(QString value, bool *ok) {
    value.replace(',', '.');
    return value.toDouble(ok);
  }

  static bool selectEquation(qint32 equation, MathFunc &f) {
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
};

#endif
