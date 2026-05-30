#include "IntegrationModule.hpp"

#include "BackendUtil.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <utility>

bool IntegrationModule::selectIntegrand(qint32 functionId, IntegrandFunc &f,
                                        std::vector<double> &discontinuities) {
  discontinuities.clear();
  switch (functionId) {
  case 0:
    f = [](double x) { return x * x + 2.0 * x - 1.0; };
    return true;
  case 1:
    f = [](double x) { return std::sin(x); };
    return true;
  case 2:
    f = [](double x) { return std::exp(x); };
    return true;
  case 3:
    f = [](double x) { return 1.0 / x; };
    discontinuities.push_back(0.0);
    return true;
  case 4:
    f = [](double x) { return 1.0 / std::sqrt(x); };
    discontinuities.push_back(0.0);
    return true;
  default:
    return false;
  }
}

bool IntegrationModule::isIntegrandDefined(qint32 functionId, double a,
                                           double b) {
  switch (functionId) {
  case 4:
    if (a < 0.0) {
      return false;
    }
    return true;
  case 3:
    return true;
  default:
    (void)a;
    (void)b;
    return true;
  }
}

QVariantMap IntegrationModule::integrate(qint32 functionId,
                                         const QVariantMap &map) {
  QVariantMap result;

  IntegrandFunc f;
  std::vector<double> disc;
  if (!selectIntegrand(functionId, f, disc)) {
    result.insert("status", QString("error"));
    result.insert("message", QString("Неизвестная функция."));
    result.insert("methods", QVariantList{});
    return result;
  }

  bool okLeft = false;
  bool okRight = false;
  bool okEps = false;

  const double a =
      parseDouble(map.value("left", QString()).toString(), &okLeft);
  const double b =
      parseDouble(map.value("right", QString()).toString(), &okRight);
  const double eps =
      parseDouble(map.value("eps", QString()).toString(), &okEps);

  if (!okLeft || !okRight) {
    result.insert("status", QString("error"));
    result.insert("message", QString("Некорректные пределы интегрирования."));
    result.insert("methods", QVariantList{});
    return result;
  }
  if (!okEps || !(eps > 0.0)) {
    result.insert("status", QString("error"));
    result.insert("message", QString("Некорректная точность ε."));
    result.insert("methods", QVariantList{});
    return result;
  }
  if (!(a < b)) {
    result.insert("status", QString("error"));
    result.insert("message",
                  QString("Левый предел должен быть меньше правого."));
    result.insert("methods", QVariantList{});
    return result;
  }
  if (!isIntegrandDefined(functionId, a, b)) {
    result.insert("status", QString("error"));
    result.insert(
        "message",
        QString("Функция не определена на отрезке (вне области допустимых "
                "значений)."));
    result.insert("methods", QVariantList{});
    return result;
  }

  LeftRectIntegrator leftRect(eps);
  RightRectIntegrator rightRect(eps);
  MidRectIntegrator midRect(eps);
  TrapezoidIntegrator trapezoid(eps);
  SimpsonIntegrator simpson(eps);

  const std::array<std::pair<QString, Integrator *>, 5> methods = {{
      {QStringLiteral("Левые прямоугольники"), &leftRect},
      {QStringLiteral("Правые прямоугольники"), &rightRect},
      {QStringLiteral("Средние прямоугольники"), &midRect},
      {QStringLiteral("Трапеции"), &trapezoid},
      {QStringLiteral("Симпсон"), &simpson},
  }};

  QVariantList list;
  bool anyOk = false;
  bool anyPrincipalValue = false;
  QString worstFailure;

  for (const auto &[name, integ] : methods) {
    IntegrationResult r = integ->integrate(f, a, b, disc);
    QVariantMap item;
    item.insert("method", name);
    item.insert("status", QString::fromStdString(r.status));
    item.insert("message", QString::fromStdString(r.message));
    item.insert("value",
                std::isfinite(r.value)
                    ? QVariant(r.value)
                    : QVariant(std::numeric_limits<double>::quiet_NaN()));
    item.insert("n", r.n);
    item.insert("runge", r.runge_error);
    list.push_back(item);

    if (r.status == "ok") {
      anyOk = true;
    } else if (r.status == "ok_principal_value") {
      anyPrincipalValue = true;
    } else {
      worstFailure = QString::fromStdString(r.status);
    }
  }

  QString overallStatus;
  if (anyOk) {
    overallStatus = "ok";
  } else if (anyPrincipalValue) {
    overallStatus = "ok_principal_value";
  } else if (!worstFailure.isEmpty()) {
    overallStatus = worstFailure;
  } else {
    overallStatus = "ok";
  }

  result.insert("status", overallStatus);
  result.insert("methods", list);
  result.insert("message", QString());
  return result;
}

QVariantList IntegrationModule::sampleIntegrand(qint32 functionId, qreal left,
                                                qreal right, qint32 points) {
  QVariantList out;
  IntegrandFunc f;
  std::vector<double> disc;
  if (!selectIntegrand(functionId, f, disc)) {
    return out;
  }
  if (!std::isfinite(left) || !std::isfinite(right) || !(left < right)) {
    left = -5.0;
    right = 5.0;
  }
  const int safePoints = std::clamp(static_cast<int>(points), 20, 3000);
  const double step = (right - left) / static_cast<double>(safePoints - 1);
  for (int i = 0; i < safePoints; ++i) {
    const double x = left + i * step;
    bool nearDisc = false;
    for (double c : disc) {
      if (std::abs(x - c) < 1e-9) {
        nearDisc = true;
        break;
      }
    }
    if (nearDisc) {
      continue;
    }
    const double y = f(x);
    if (!std::isfinite(y)) {
      continue;
    }
    QVariantMap point;
    point.insert("x", x);
    point.insert("y", y);
    out.push_back(point);
  }
  return out;
}

QVariantList IntegrationModule::integrandDiscontinuities(qint32 functionId) {
  QVariantList out;
  IntegrandFunc f;
  std::vector<double> disc;
  if (!selectIntegrand(functionId, f, disc)) {
    return out;
  }
  for (double c : disc) {
    out.push_back(c);
  }
  return out;
}
