#include "ApproximationModule.hpp"

#include "BackendUtil.hpp"
#include "../calc/Approximation.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace {

QString kindKey(approx::Kind k) {
  using approx::Kind;
  switch (k) {
  case Kind::Linear:
    return QStringLiteral("linear");
  case Kind::Poly2:
    return QStringLiteral("poly2");
  case Kind::Poly3:
    return QStringLiteral("poly3");
  case Kind::Exponential:
    return QStringLiteral("exp");
  case Kind::Logarithmic:
    return QStringLiteral("log");
  case Kind::Power:
    return QStringLiteral("power");
  }
  return {};
}

approx::Kind keyToKind(const QString &k) {
  using approx::Kind;
  if (k == QStringLiteral("linear"))
    return Kind::Linear;
  if (k == QStringLiteral("poly2"))
    return Kind::Poly2;
  if (k == QStringLiteral("poly3"))
    return Kind::Poly3;
  if (k == QStringLiteral("exp"))
    return Kind::Exponential;
  if (k == QStringLiteral("log"))
    return Kind::Logarithmic;
  return Kind::Power;
}

QString kindTitle(approx::Kind k) {
  using approx::Kind;
  switch (k) {
  case Kind::Linear:
    return QStringLiteral("Линейная — φ(x) = a·x + b");
  case Kind::Poly2:
    return QStringLiteral("Полином 2-й степени — φ(x) = a₀ + a₁·x + a₂·x²");
  case Kind::Poly3:
    return QStringLiteral(
        "Полином 3-й степени — φ(x) = a₀ + a₁·x + a₂·x² + a₃·x³");
  case Kind::Exponential:
    return QStringLiteral("Экспоненциальная — φ(x) = a·exp(b·x)");
  case Kind::Logarithmic:
    return QStringLiteral("Логарифмическая — φ(x) = a·ln(x) + b");
  case Kind::Power:
    return QStringLiteral("Степенная — φ(x) = a·x^b");
  }
  return {};
}

QString shortTitle(approx::Kind k) {
  using approx::Kind;
  switch (k) {
  case Kind::Linear:
    return QStringLiteral("Линейная");
  case Kind::Poly2:
    return QStringLiteral("Полином 2");
  case Kind::Poly3:
    return QStringLiteral("Полином 3");
  case Kind::Exponential:
    return QStringLiteral("Экспонента");
  case Kind::Logarithmic:
    return QStringLiteral("Логарифм");
  case Kind::Power:
    return QStringLiteral("Степенная");
  }
  return {};
}

QString fmt(double v) { return QString::number(v, 'g', 6); }

QString formula(const approx::Result &r) {
  using approx::Kind;
  const auto &c = r.coeffs;
  switch (r.kind) {
  case Kind::Linear:
    return QStringLiteral("%1·x + %2").arg(fmt(c[0]), fmt(c[1]));
  case Kind::Poly2:
    return QStringLiteral("%1 + %2·x + %3·x²")
        .arg(fmt(c[0]), fmt(c[1]), fmt(c[2]));
  case Kind::Poly3:
    return QStringLiteral("%1 + %2·x + %3·x² + %4·x³")
        .arg(fmt(c[0]), fmt(c[1]), fmt(c[2]), fmt(c[3]));
  case Kind::Exponential:
    return QStringLiteral("%1·exp(%2·x)").arg(fmt(c[0]), fmt(c[1]));
  case Kind::Logarithmic:
    return QStringLiteral("%1·ln(x) + %2").arg(fmt(c[0]), fmt(c[1]));
  case Kind::Power:
    return QStringLiteral("%1·x^(%2)").arg(fmt(c[0]), fmt(c[1]));
  }
  return {};
}

QString statusKey(approx::Status s) {
  using approx::Status;
  switch (s) {
  case Status::Ok:
    return QStringLiteral("ok");
  case Status::TooFew:
    return QStringLiteral("too_few");
  case Status::TooMany:
    return QStringLiteral("too_many");
  case Status::NonPositiveX:
    return QStringLiteral("non_positive_x");
  case Status::NonPositiveY:
    return QStringLiteral("non_positive_y");
  case Status::Degenerate:
    return QStringLiteral("degenerate");
  }
  return {};
}

QString statusMessage(approx::Status s) {
  using approx::Status;
  switch (s) {
  case Status::Ok:
    return QStringLiteral("Готово");
  case Status::TooFew:
    return QStringLiteral("Требуется не менее 4 точек");
  case Status::TooMany:
    return QStringLiteral("Допустимо не более 12 точек");
  case Status::NonPositiveX:
    return QStringLiteral("Неприменимо: требуется xᵢ > 0");
  case Status::NonPositiveY:
    return QStringLiteral("Неприменимо: требуется yᵢ > 0");
  case Status::Degenerate:
    return QStringLiteral("Вырожденная система нормальных уравнений");
  }
  return {};
}

QString r2Verdict(double r2) {
  if (r2 >= 0.95)
    return QStringLiteral("Высокая точность");
  if (r2 >= 0.75)
    return QStringLiteral("Удовлетворительно");
  if (r2 >= 0.50)
    return QStringLiteral("Слабая аппроксимация");
  return QStringLiteral("Точность недостаточна");
}

QVariantList toVariant(const std::vector<double> &v) {
  QVariantList out;
  out.reserve(static_cast<qsizetype>(v.size()));
  for (double x : v) {
    out.push_back(x);
  }
  return out;
}

bool parseDoubleField(const QVariant &v, double &out) {
  bool ok = false;
  out = parseDouble(v.toString(), &ok);
  return ok && std::isfinite(out);
}

QVariantMap resultBlock(const approx::Result &r) {
  QVariantMap m;
  m.insert("kind", kindKey(r.kind));
  m.insert("title", kindTitle(r.kind));
  m.insert("shortTitle", shortTitle(r.kind));
  m.insert("status", statusKey(r.status));
  m.insert("statusMessage", statusMessage(r.status));
  const bool ok = r.status == approx::Status::Ok;
  m.insert("formula", ok ? formula(r) : QString{});
  m.insert("coeffs", ok ? toVariant(r.coeffs) : QVariantList{});
  m.insert("phi", ok ? toVariant(r.phi) : QVariantList{});
  m.insert("eps", ok ? toVariant(r.eps) : QVariantList{});
  m.insert("S",
           ok ? QVariant(r.S)
              : QVariant(std::numeric_limits<double>::quiet_NaN()));
  m.insert("delta",
           ok ? QVariant(r.delta)
              : QVariant(std::numeric_limits<double>::quiet_NaN()));
  m.insert("r2",
           ok ? QVariant(r.r2)
              : QVariant(std::numeric_limits<double>::quiet_NaN()));
  if (ok && r.pearson.has_value()) {
    m.insert("pearson", QVariant(*r.pearson));
  } else {
    m.insert("pearson", QVariant{});
  }
  m.insert("r2Verdict", ok ? r2Verdict(r.r2) : QString{});
  return m;
}

} // namespace

QVariantMap ApproximationModule::approximate(const QVariantMap &payload) {
  QVariantMap result;

  const QVariantList pts = payload.value("points").toList();
  std::vector<approx::Point> data;
  data.reserve(static_cast<std::size_t>(pts.size()));
  for (qsizetype i = 0; i < pts.size(); ++i) {
    const QVariantMap entry = pts[i].toMap();
    double xv = 0.0;
    double yv = 0.0;
    if (!parseDoubleField(entry.value("x"), xv) ||
        !parseDoubleField(entry.value("y"), yv)) {
      result.insert("status", QStringLiteral("error"));
      result.insert("message",
                    QStringLiteral("Некорректное число в точке #%1")
                        .arg(static_cast<int>(i) + 1));
      return result;
    }
    data.push_back({xv, yv});
  }

  if (data.size() <
      approx::LeastSquaresApproximator::kMinPoints) {
    result.insert("status", QStringLiteral("error"));
    result.insert(
        "message",
        QStringLiteral("Требуется не менее %1 точек")
            .arg(static_cast<int>(
                approx::LeastSquaresApproximator::kMinPoints)));
    return result;
  }
  if (data.size() >
      approx::LeastSquaresApproximator::kMaxPoints) {
    result.insert("status", QStringLiteral("error"));
    result.insert(
        "message",
        QStringLiteral("Допустимо не более %1 точек")
            .arg(static_cast<int>(
                approx::LeastSquaresApproximator::kMaxPoints)));
    return result;
  }

  double xMin = data[0].x;
  double xMax = data[0].x;
  for (const auto &p : data) {
    xMin = std::min(xMin, p.x);
    xMax = std::max(xMax, p.x);
  }
  if (std::abs(xMax - xMin) < 1e-12) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message",
                  QStringLiteral("Все x совпадают — нечего аппроксимировать"));
    return result;
  }

  approx::LeastSquaresApproximator approximator;
  const auto results = approximator.approximateAll(data);

  QVariantList methods;
  int bestIdx = -1;
  double bestDelta = std::numeric_limits<double>::infinity();
  for (std::size_t i = 0; i < results.size(); ++i) {
    methods.push_back(resultBlock(results[i]));
    if (results[i].status == approx::Status::Ok &&
        results[i].delta < bestDelta) {
      bestDelta = results[i].delta;
      bestIdx = static_cast<int>(i);
    }
  }

  QVariantList pointsOut;
  for (const auto &p : data) {
    QVariantMap pm;
    pm.insert("x", p.x);
    pm.insert("y", p.y);
    pointsOut.push_back(pm);
  }

  result.insert("status", QStringLiteral("ok"));
  result.insert("points", pointsOut);
  result.insert("xMin", xMin);
  result.insert("xMax", xMax);
  result.insert("methods", methods);
  if (bestIdx >= 0) {
    const auto &best = results[static_cast<std::size_t>(bestIdx)];
    result.insert("best", bestIdx);
    result.insert("bestMessage",
                  QStringLiteral("Наилучшая аппроксимация — %1: δ = %2")
                      .arg(shortTitle(best.kind))
                      .arg(QString::number(best.delta, 'g', 4)));
  } else {
    result.insert("best", -1);
    result.insert("bestMessage",
                  QStringLiteral("Ни одна модель не применима к данным"));
  }

  return result;
}

QVariantList ApproximationModule::sampleApproximation(const QString &kindStr,
                                                     const QVariantList &coeffs,
                                                     double xMin, double xMax,
                                                     qint32 points) {
  QVariantList out;
  if (points < 2 || xMax <= xMin) {
    return out;
  }

  approx::Result r;
  r.kind = keyToKind(kindStr);
  r.status = approx::Status::Ok;
  r.coeffs.reserve(static_cast<std::size_t>(coeffs.size()));
  for (const auto &v : coeffs) {
    bool ok = false;
    const double d = v.toDouble(&ok);
    if (!ok || !std::isfinite(d)) {
      return {};
    }
    r.coeffs.push_back(d);
  }

  out.reserve(points);
  const double step = (xMax - xMin) / (points - 1);
  for (qint32 i = 0; i < points; ++i) {
    const double x = xMin + step * static_cast<double>(i);
    const double y = approx::LeastSquaresApproximator::evaluate(r, x);
    QVariantMap pm;
    pm.insert("x", x);
    pm.insert("y", y);
    out.push_back(pm);
  }
  return out;
}
