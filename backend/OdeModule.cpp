#include "OdeModule.hpp"

#include "../calc/Ode.hpp"
#include "BackendUtil.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

namespace {

QString statusMessage(ode::Status s) {
  switch (s) {
  case ode::Status::Ok:
    return QStringLiteral("Готово");
  case ode::Status::BadInterval:
    return QStringLiteral("Конец отрезка xₙ должен быть больше начала x₀");
  case ode::Status::BadStep:
    return QStringLiteral("Шаг h должен быть положительным");
  case ode::Status::StepTooLarge:
    return QStringLiteral("Шаг h не должен превышать длину отрезка (xₙ − x₀)");
  case ode::Status::BadTolerance:
    return QStringLiteral("Точность ε должна быть положительной");
  case ode::Status::TooFewNodes:
    return QStringLiteral(
        "Для метода Милна нужно не менее 4 шагов (узлов ≥ 5) — уменьшите h");
  case ode::Status::TooManyNodes:
    return QStringLiteral("Слишком маленький шаг h — более 100000 узлов");
  }
  return {};
}

double quietNaN() { return std::numeric_limits<double>::quiet_NaN(); }

QVariant num(double v) {
  return std::isfinite(v) ? QVariant(v) : QVariant(quietNaN());
}

bool parseField(const QVariant &v, double &out) {
  bool ok = false;
  out = parseDouble(v.toString(), &ok);
  return ok && std::isfinite(out);
}

QVariantMap summaryBlock(const ode::MethodSummary &s) {
  QVariantMap m;
  m.insert("key", QString::fromUtf8(ode::methodKey(s.method)));
  m.insert("title", QString::fromUtf8(ode::methodTitle(s.method)));
  m.insert("order", s.order);
  m.insert("usesRunge", s.usesRunge);
  m.insert("runge", s.usesRunge ? num(s.rungeError) : QVariant(quietNaN()));
  m.insert("exactError", num(s.exactError));
  m.insert("steps", s.steps);
  m.insert("refinedStep",
           s.usesRunge ? num(s.refinedStep) : QVariant(quietNaN()));
  m.insert("refinedSteps", s.usesRunge ? QVariant(s.refinedSteps) : QVariant());
  m.insert("refinedError",
           s.usesRunge ? num(s.refinedError) : QVariant(quietNaN()));
  return m;
}

} // namespace

QVariantMap OdeModule::solve(const QVariantMap &payload) {
  QVariantMap result;

  bool okId = false;
  const int equationId = payload.value("equationId").toInt(&okId);
  if (!okId || !ode::equationExists(equationId)) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message", QStringLiteral("Неизвестное уравнение"));
    return result;
  }

  struct Field {
    const char *key;
    const char *label;
  };
  const Field fields[] = {
      {"x0", "x₀"}, {"y0", "y₀"}, {"xn", "xₙ"}, {"h", "h"}, {"eps", "ε"}};
  double vals[5] = {0.0, 0.0, 0.0, 0.0, 0.0};
  for (int i = 0; i < 5; ++i) {
    if (!parseField(payload.value(QString::fromUtf8(fields[i].key)), vals[i])) {
      result.insert("status", QStringLiteral("error"));
      result.insert("message", QStringLiteral("Некорректное число: %1")
                                   .arg(QString::fromUtf8(fields[i].label)));
      return result;
    }
  }

  const ode::Result r =
      ode::solveCauchy(equationId, vals[0], vals[1], vals[2], vals[3], vals[4]);
  if (r.status != ode::Status::Ok) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message", statusMessage(r.status));
    return result;
  }

  QVariantList table;
  table.reserve(static_cast<qsizetype>(r.table.size()));
  for (const ode::Node &nd : r.table) {
    QVariantMap row;
    row.insert("x", nd.x);
    row.insert("exact", num(nd.yExact));
    row.insert("improved_euler", num(nd.yImprovedEuler));
    row.insert("rk4", num(nd.yRungeKutta4));
    row.insert("milne", num(nd.yMilne));
    table.push_back(row);
  }

  QVariantList methods;
  methods.push_back(summaryBlock(r.improvedEuler));
  methods.push_back(summaryBlock(r.rungeKutta4));
  methods.push_back(summaryBlock(r.milne));

  result.insert("status", QStringLiteral("ok"));
  result.insert("message", QString());
  result.insert("equationId", equationId);
  result.insert("equationTitle",
                QString::fromUtf8(ode::equationTitle(equationId)));
  result.insert("x0", r.x0);
  result.insert("xn", r.xn);
  result.insert("h", r.h);
  result.insert("eps", r.eps);
  result.insert("nodeCount", static_cast<int>(r.table.size()));
  result.insert("table", table);
  result.insert("methods", methods);
  return result;
}

QVariantList OdeModule::equationList() {
  QVariantList out;
  for (const ode::OdeEquation &eq : ode::equations()) {
    QVariantMap m;
    m.insert("id", eq.id);
    m.insert("title", QString::fromUtf8(ode::equationTitle(eq.id)));
    out.push_back(m);
  }
  return out;
}

QVariantList OdeModule::sampleExact(qint32 equationId, double x0, double y0,
                                    double a, double b, qint32 points) {
  QVariantList out;
  if (!ode::equationExists(equationId)) {
    return out;
  }
  if (!std::isfinite(a) || !std::isfinite(b) || !(a < b)) {
    return out;
  }
  const ode::Exact exact =
      ode::equations()[static_cast<std::size_t>(equationId)].makeExact(x0, y0);
  const int safePoints = std::clamp(static_cast<int>(points), 20, 3000);
  const double step = (b - a) / static_cast<double>(safePoints - 1);
  for (int i = 0; i < safePoints; ++i) {
    const double x = a + i * step;
    const double y = exact(x);
    if (!std::isfinite(y)) {
      continue;
    }
    QVariantMap pm;
    pm.insert("x", x);
    pm.insert("y", y);
    out.push_back(pm);
  }
  return out;
}
