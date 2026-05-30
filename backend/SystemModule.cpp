#include "SystemModule.hpp"

#include "BackendUtil.hpp"

#include <QtConcurrent/QtConcurrent>

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <numeric>

bool SystemModule::selectSystemIterFunctions(qint32 equation, SystemFunc &phiX,
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

SystemModule::SystemFunctions SystemModule::systemFunctions(qint32 equation) {
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

QVector<QPointF>
SystemModule::traceZeroCurve(const std::function<double(double, double)> &F,
                             double left, double right, double bottom,
                             double top, int samples) {
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
  for (const auto &c : columns)
    total += c.size();
  for (const auto &r : rows)
    total += r.size();
  merged.reserve(total);
  for (const auto &c : columns)
    merged.append(c);
  for (const auto &r : rows)
    merged.append(r);
  return merged;
}

QVariantList SystemModule::toVariantList(const QVector<QPointF> &points) {
  QVariantList out;
  out.reserve(points.size());
  for (const QPointF &p : points) {
    out.push_back(QVariant::fromValue(p));
  }
  return out;
}

QVariantMap SystemModule::processSystemData(const QVariantMap &map) {
  return processSystemDataByEquation(0, map);
}

QVariantMap SystemModule::processSystemDataByEquation(qint32 equation,
                                                      const QVariantMap &map) {
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

QVariantMap SystemModule::sampleSystemCurves(qreal left, qreal right,
                                             qreal bottom, qreal top,
                                             qint32 points) {
  return sampleSystemCurvesByEquation(0, left, right, bottom, top, points);
}

QVariantMap SystemModule::sampleSystemCurvesByEquation(qint32 equation,
                                                       qreal left, qreal right,
                                                       qreal bottom, qreal top,
                                                       qint32 points) {
  QVariantMap result;

  if (!std::isfinite(left) || !std::isfinite(right) || !std::isfinite(bottom) ||
      !std::isfinite(top) || !(left < right) || !(bottom < top)) {
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
  const auto tracedFirst =
      traceZeroCurve(system.first, left, right, bottom, top, safePoints);
  const auto tracedSecond =
      traceZeroCurve(system.second, left, right, bottom, top, safePoints);

  result.insert("first", toVariantList(tracedFirst));
  result.insert("second", toVariantList(tracedSecond));
  return result;
}
