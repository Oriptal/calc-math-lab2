#ifndef BACKEND_H
#define BACKEND_H

#include "calc/Solvers.hpp"

#include <QObject>
#include <QPointF>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>
#include <QtConcurrent/QtConcurrent>

#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
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

  Q_INVOKABLE QVariantMap processSystemData(const QVariantMap &map) const {
    return processSystemDataByEquation(0, map);
  }

  Q_INVOKABLE QVariantMap
  processSystemDataByEquation(qint32 equation, const QVariantMap &map) const {
    QVariantMap result;

    bool okLeft = false;
    bool okRight = false;
    bool okBottom = false;
    bool okTop = false;
    bool okEps = false;

    const double left =
        parseDouble(map.value("left", QString()).toString(), &okLeft);
    const double right =
        parseDouble(map.value("right", QString()).toString(), &okRight);
    const double bottom =
        parseDouble(map.value("bottom", QString()).toString(), &okBottom);
    const double top =
        parseDouble(map.value("top", QString()).toString(), &okTop);
    const double eps =
        parseDouble(map.value("eps", QString()).toString(), &okEps);

    if (!okEps) {
      result.insert("status", static_cast<qint32>(INCORRECT_EPS));
      result.insert("x", std::numeric_limits<qreal>::quiet_NaN());
      result.insert("y", std::numeric_limits<qreal>::quiet_NaN());
      return result;
    }
    if (!okLeft || !okRight || !okBottom || !okTop || !(left < right) ||
        !(bottom < top)) {
      result.insert("status", static_cast<qint32>(INCORRECT_BORDERS));
      result.insert("x", std::numeric_limits<qreal>::quiet_NaN());
      result.insert("y", std::numeric_limits<qreal>::quiet_NaN());
      return result;
    }
    if (!(eps > 0.0) || !std::isfinite(eps)) {
      result.insert("status", static_cast<qint32>(INCORRECT_EPS));
      result.insert("x", std::numeric_limits<qreal>::quiet_NaN());
      result.insert("y", std::numeric_limits<qreal>::quiet_NaN());
      return result;
    }

    SystemFunc phiX;
    SystemFunc phiY;
    if (!selectSystemIterFunctions(equation, phiX, phiY)) {
      result.insert("status", static_cast<qint32>(INCORRECT_BORDERS));
      result.insert("x", std::numeric_limits<qreal>::quiet_NaN());
      result.insert("y", std::numeric_limits<qreal>::quiet_NaN());
      return result;
    }

    const double startX = (left + right) / 2.0;
    const double startY = (bottom + top) / 2.0;

    const std::array<QPointF, 5> guesses = {{
        QPointF(startX, startY),
        QPointF(left, bottom),
        QPointF(left, top),
        QPointF(right, bottom),
        QPointF(right, top),
    }};

    SystemIterSolver solver(eps);
    for (const QPointF &guess : guesses) {

      const auto [pairFirst, pairSecond] =
          solver.solve(phiX, phiY, guess.x(), guess.y());
      auto [iterFirst, rootX] = pairFirst;
      auto [iter, rootY] = pairSecond;
      if (!std::isfinite(rootX) || !std::isfinite(rootY)) {
        continue;
      }

      if (rootX < left - eps || rootX > right + eps || rootY < bottom - eps ||
          rootY > top + eps) {
        continue;
      }

      result.insert("status", static_cast<qint32>(SUCCESS));
      result.insert("x", rootX);
      result.insert("y", rootY);
      result.insert("iter", iter);
      return result;
    }

    result.insert("status", static_cast<qint32>(METHOD_DIVERGENCE));
    result.insert("x", std::numeric_limits<qreal>::quiet_NaN());
    result.insert("y", std::numeric_limits<qreal>::quiet_NaN());
    return result;
  }

  Q_INVOKABLE QVariantMap sampleSystemCurves(qreal left, qreal right,
                                             qreal bottom, qreal top,
                                             qint32 points) const {
    return sampleSystemCurvesByEquation(0, left, right, bottom, top, points);
  }

  Q_INVOKABLE QVariantMap sampleSystemCurvesByEquation(qint32 equation,
                                                       qreal left, qreal right,
                                                       qreal bottom, qreal top,
                                                       qint32 points) const {
    QVariantMap result;

    if (!std::isfinite(left) || !std::isfinite(right) ||
        !std::isfinite(bottom) || !std::isfinite(top) || !(left < right) ||
        !(bottom < top)) {
      left = -1.2;
      right = 1.2;
      bottom = -1.2;
      top = 1.2;
    }

    const auto system = systemFunctions(equation);
    if (!system.first || !system.second) {
      result.insert("first", QVariantList{});
      result.insert("second", QVariantList{});
      return result;
    }

    const int safePoints = std::clamp(static_cast<int>(points), 80, 800);
    const auto tracedFirst = traceZeroCurve(system.first, left, right, bottom, top, safePoints);
    const auto tracedSecond = traceZeroCurve(system.second, left, right, bottom, top, safePoints);

    result.insert("first", toVariantList(tracedFirst));
    result.insert("second", toVariantList(tracedSecond));
    return result;
  }

private:
  struct SystemFunctions {
    std::function<double(double, double)> first;
    std::function<double(double, double)> second;
  };

  static double parseDouble(QString value, bool *ok) {
    value.replace(',', '.');
    return value.toDouble(ok);
  }

  static QVariantList toVariantList(const QVector<QPointF> &points) {
    QVariantList out;
    out.reserve(points.size());
    for (const QPointF &p : points) {
      out.push_back(QVariant::fromValue(p));
    }
    return out;
  }

  static QVector<QPointF>
  traceZeroCurve(const std::function<double(double, double)> &F, double left,
                 double right, double bottom, double top, int samples) {
    if (!F || samples < 2) {
      return {};
    }

    const double stepX = (right - left) / static_cast<double>(samples - 1);
    const double stepY = (top - bottom) / static_cast<double>(samples - 1);

    QVector<int> columnIndex(samples);
    std::iota(columnIndex.begin(), columnIndex.end(), 0);

    auto scanColumn = [&](int ix) -> QVector<QPointF> {
      QVector<QPointF> out;
      out.reserve(8);
      const double x = left + ix * stepX;
      double prevF = F(x, bottom);
      for (int iy = 1; iy < samples; ++iy) {
        const double y = bottom + iy * stepY;
        const double curF = F(x, y);
        if (std::isfinite(prevF) && std::isfinite(curF) && prevF * curF <= 0.0) {
          const double denom = prevF - curF;
          const double t = std::abs(denom) > 1e-18 ? prevF / denom : 0.5;
          const double yPrev = y - stepY;
          out.push_back(QPointF(x, yPrev + t * stepY));
        }
        prevF = curF;
      }
      return out;
    };

    auto scanRow = [&](int iy) -> QVector<QPointF> {
      QVector<QPointF> out;
      out.reserve(8);
      const double y = bottom + iy * stepY;
      double prevF = F(left, y);
      for (int ix = 1; ix < samples; ++ix) {
        const double x = left + ix * stepX;
        const double curF = F(x, y);
        if (std::isfinite(prevF) && std::isfinite(curF) && prevF * curF <= 0.0) {
          const double denom = prevF - curF;
          const double t = std::abs(denom) > 1e-18 ? prevF / denom : 0.5;
          const double xPrev = x - stepX;
          out.push_back(QPointF(xPrev + t * stepX, y));
        }
        prevF = curF;
      }
      return out;
    };

    auto columns = QtConcurrent::blockingMapped<QVector<QVector<QPointF>>>(
        columnIndex, scanColumn);
    auto rows = QtConcurrent::blockingMapped<QVector<QVector<QPointF>>>(
        columnIndex, scanRow);

    QVector<QPointF> merged;
    qsizetype total = 0;
    for (const auto &c : columns) total += c.size();
    for (const auto &r : rows) total += r.size();
    merged.reserve(total);
    for (const auto &c : columns) merged.append(c);
    for (const auto &r : rows) merged.append(r);
    return merged;
  }

  static SystemFunctions systemFunctions(qint32 equation) {
    switch (equation) {
    case 0:
      return {
          [](double x, double y) { return std::cos(x + 0.5) + y - 1.0; },
          [](double x, double y) { return std::sin(y) - 2.0 * x - 2.0; },
      };
    case 1:
      return {
          [](double x, double y) { return std::sin(y + 0.5) - x - 1.0; },
          [](double x, double y) { return y + std::cos(x - 2.0); },
      };
    case 2:
      return {
          [](double x, double y) { return std::cos(y) + x - 1.5; },
          [](double x, double y) { return 2.0 * y - std::cos(x - 0.5); },
      };
    default:
      return {};
    }
  }

  static bool selectSystemIterFunctions(qint32 equation, SystemFunc &phiX,
                                        SystemFunc &phiY) {
    switch (equation) {
    case 0:
      phiX = [](double, double y) { return 0.5 * std::sin(y) - 1.0; };
      phiY = [](double x, double) { return 1.0 - std::cos(x + 0.5); };
      return true;
    case 1:
      phiX = [](double, double y) { return std::sin(y + 0.5) - 1.0; };
      phiY = [](double x, double) { return -std::cos(x - 2.0); };
      return true;
    case 2:
      phiX = [](double, double y) { return 1.5 - std::cos(y); };
      phiY = [](double x, double) { return 0.5 * std::cos(x - 0.5); };
      return true;
    default:
      return false;
    }
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
