#include "InterpolationModule.hpp"

#include "../calc/Interpolation.hpp"
#include "BackendUtil.hpp"

#include <QFile>
#include <QRegularExpression>
#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace {

constexpr int kMaxNodes = 30;

QString fmt(double v) { return QString::number(v, 'g', 6); }

QString statusKey(interp::Status s) {
  switch (s) {
  case interp::Status::Ok:
    return QStringLiteral("ok");
  case interp::Status::NotEquidistant:
    return QStringLiteral("not_equidistant");
  case interp::Status::TooFew:
    return QStringLiteral("too_few");
  case interp::Status::Duplicate:
    return QStringLiteral("duplicate");
  }
  return {};
}

QString statusMessage(interp::Status s) {
  switch (s) {
  case interp::Status::Ok:
    return QStringLiteral("Готово");
  case interp::Status::NotEquidistant:
    return QStringLiteral("Неприменимо: нужны равноотстоящие узлы");
  case interp::Status::TooFew:
    return QStringLiteral("Требуется не менее 2 узлов");
  case interp::Status::Duplicate:
    return QStringLiteral("Совпадающие узлы x");
  }
  return {};
}

double evalFunction(qint32 id, double x) {
  switch (id) {
  case 0:
    return std::sin(x);
  case 1:
    return std::cos(x);
  case 2:
    return std::exp(x);
  case 3:
    return 1.0 / (1.0 + x * x);
  case 4:
    return x * std::sin(x);
  default:
    return 0.0;
  }
}

bool parseField(const QVariant &v, double &out) {
  bool ok = false;
  out = parseDouble(v.toString(), &ok);
  return ok && std::isfinite(out);
}

QVariantMap methodBlock(const interp::MethodResult &mr) {
  QVariantMap m;
  m.insert("key", QString::fromUtf8(interp::methodKey(mr.method)));
  m.insert("title", QString::fromUtf8(interp::methodTitle(mr.method)));
  m.insert("statusKey", statusKey(mr.status));
  m.insert("statusMessage", statusMessage(mr.status));
  const bool ok = mr.status == interp::Status::Ok;
  m.insert("value", ok ? QVariant(mr.value)
                       : QVariant(std::numeric_limits<double>::quiet_NaN()));
  m.insert("t", mr.t);
  m.insert("center", mr.center);
  m.insert("order", mr.order);
  return m;
}

bool methodFromKey(const QString &key, interp::Method &out) {
  const interp::Method all[] = {
      interp::Method::Lagrange,       interp::Method::NewtonForward,
      interp::Method::NewtonBackward, interp::Method::GaussI,
      interp::Method::GaussII,        interp::Method::Stirling,
      interp::Method::Bessel};
  for (interp::Method m : all) {
    if (key == QString::fromUtf8(interp::methodKey(m))) {
      out = m;
      return true;
    }
  }
  return false;
}

QVariantMap parsePoints(const QString &text) {
  QVariantMap out;
  QVariantList pts;
  const QRegularExpression sep(QStringLiteral("[\\s,;]+"));
  double target = 0.0;
  bool hasTarget = false;

  const QStringList lines = text.split('\n');
  for (const QString &raw : lines) {
    QString line = raw.trimmed();
    if (line.isEmpty()) {
      continue;
    }
    const bool comment = line.startsWith('#');
    QString body = comment ? line.mid(1).trimmed() : line;
    const QStringList parts = body.split(sep, Qt::SkipEmptyParts);
    if (parts.isEmpty()) {
      continue;
    }
    if (parts[0].compare(QStringLiteral("target"), Qt::CaseInsensitive) == 0 &&
        parts.size() >= 2) {
      bool ok = false;
      const double tv = parseDouble(parts[1], &ok);
      if (ok) {
        target = tv;
        hasTarget = true;
      }
      continue;
    }
    if (comment || parts.size() < 2) {
      continue;
    }
    bool okX = false;
    bool okY = false;
    const double x = parseDouble(parts[0], &okX);
    const double y = parseDouble(parts[1], &okY);
    if (okX && okY) {
      QVariantMap pm;
      pm.insert("x", x);
      pm.insert("y", y);
      pts.push_back(pm);
    }
  }

  out.insert("points", pts);
  if (hasTarget) {
    out.insert("target", target);
  }
  return out;
}

} // namespace

QVariantMap InterpolationModule::interpolate(const QVariantMap &payload) {
  QVariantMap result;

  const QVariantList pts = payload.value("points").toList();
  std::vector<interp::Point> nodes;
  nodes.reserve(static_cast<std::size_t>(pts.size()));
  for (qsizetype i = 0; i < pts.size(); ++i) {
    const QVariantMap entry = pts[i].toMap();
    double xv = 0.0;
    double yv = 0.0;
    if (!parseField(entry.value("x"), xv) ||
        !parseField(entry.value("y"), yv)) {
      result.insert("status", QStringLiteral("error"));
      result.insert("message", QStringLiteral("Некорректное число в узле #%1")
                                   .arg(static_cast<int>(i) + 1));
      return result;
    }
    nodes.push_back({xv, yv});
  }

  double X = 0.0;
  if (!parseField(payload.value("target"), X)) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message",
                  QStringLiteral("Некорректная точка интерполяции X"));
    return result;
  }

  if (nodes.size() < interp::kMinPoints) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message", QStringLiteral("Требуется не менее 2 узлов"));
    return result;
  }
  if (nodes.size() > static_cast<std::size_t>(kMaxNodes)) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message",
                  QStringLiteral("Допустимо не более %1 узлов").arg(kMaxNodes));
    return result;
  }

  std::sort(
      nodes.begin(), nodes.end(),
      [](const interp::Point &a, const interp::Point &b) { return a.x < b.x; });

  for (std::size_t i = 1; i < nodes.size(); ++i) {
    if (std::abs(nodes[i].x - nodes[i - 1].x) < 1e-9) {
      result.insert("status", QStringLiteral("error"));
      result.insert(
          "message",
          QStringLiteral("Совпадающие узлы x = %1").arg(fmt(nodes[i].x)));
      return result;
    }
  }

  double h = 0.0;
  const bool equidistant = interp::isEquidistant(nodes, h);
  const auto diff = interp::finiteDifferences(nodes);

  QVariantList nodesOut;
  for (const auto &p : nodes) {
    QVariantMap pm;
    pm.insert("x", p.x);
    pm.insert("y", p.y);
    nodesOut.push_back(pm);
  }

  QVariantList diffOut;
  for (const auto &column : diff) {
    QVariantList col;
    col.reserve(static_cast<qsizetype>(column.size()));
    for (double v : column) {
      col.push_back(v);
    }
    diffOut.push_back(col);
  }

  const interp::Method order[] = {
      interp::Method::Lagrange,       interp::Method::NewtonForward,
      interp::Method::NewtonBackward, interp::Method::GaussI,
      interp::Method::GaussII,        interp::Method::Stirling,
      interp::Method::Bessel};

  QVariantList methods;
  for (interp::Method m : order) {
    methods.push_back(methodBlock(interp::run(m, nodes, X)));
  }

  result.insert("status", QStringLiteral("ok"));
  result.insert("equidistant", equidistant);
  result.insert("h", equidistant ? QVariant(h) : QVariant());
  result.insert("target", X);
  result.insert("nodeCount", static_cast<int>(nodes.size()));
  result.insert("nodes", nodesOut);
  result.insert("diffTable", diffOut);
  result.insert("methods", methods);
  return result;
}

QVariantList InterpolationModule::sampleInterpolationMethod(
    const QString &methodKey, const QVariantList &points, double xMin,
    double xMax, qint32 samples) {
  QVariantList out;
  interp::Method method = interp::Method::Lagrange;
  if (samples < 2 || xMax <= xMin || !methodFromKey(methodKey, method)) {
    return out;
  }

  std::vector<interp::Point> nodes;
  nodes.reserve(static_cast<std::size_t>(points.size()));
  for (const auto &v : points) {
    const QVariantMap pm = v.toMap();
    bool okX = false;
    bool okY = false;
    const double x = parseDouble(pm.value("x").toString(), &okX);
    const double y = parseDouble(pm.value("y").toString(), &okY);
    if (okX && okY) {
      nodes.push_back({x, y});
    }
  }
  if (nodes.size() < 2) {
    return out;
  }
  std::sort(
      nodes.begin(), nodes.end(),
      [](const interp::Point &a, const interp::Point &b) { return a.x < b.x; });

  out.reserve(samples);
  const double step = (xMax - xMin) / (samples - 1);
  for (qint32 i = 0; i < samples; ++i) {
    const double x = xMin + step * static_cast<double>(i);
    const interp::MethodResult mr = interp::run(method, nodes, x);
    if (mr.status != interp::Status::Ok || !std::isfinite(mr.value)) {
      continue;
    }
    QVariantMap pm;
    pm.insert("x", x);
    pm.insert("y", mr.value);
    out.push_back(pm);
  }
  return out;
}

QVariantList InterpolationModule::functionList() {
  const char *titles[] = {"sin(x)", "cos(x)", "eˣ", "1/(1+x²)", "x·sin(x)"};
  QVariantList out;
  for (int i = 0; i < 5; ++i) {
    QVariantMap m;
    m.insert("id", i);
    m.insert("title", QString::fromUtf8(titles[i]));
    out.push_back(m);
  }
  return out;
}

QVariantList InterpolationModule::sampleFunction(qint32 funcId, double a,
                                                 double b, qint32 points) {
  QVariantList out;
  if (points < 1 || b < a) {
    return out;
  }
  out.reserve(points);
  const double step = points > 1 ? (b - a) / (points - 1) : 0.0;
  for (qint32 i = 0; i < points; ++i) {
    const double x = a + step * static_cast<double>(i);
    const double y = evalFunction(funcId, x);
    QVariantMap pm;
    pm.insert("x", x);
    pm.insert("y", y);
    out.push_back(pm);
  }
  return out;
}

QVariantMap InterpolationModule::loadFile(const QUrl &url) {
  QVariantMap result;
  const QString path = url.toLocalFile();
  if (path.isEmpty()) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message", QStringLiteral("Некорректный путь к файлу"));
    return result;
  }
  QFile f(path);
  if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message", QStringLiteral("Не удалось открыть файл"));
    return result;
  }
  const QString text = QString::fromUtf8(f.readAll());
  QVariantMap parsed = parsePoints(text);
  const QVariantList pts = parsed.value("points").toList();
  if (pts.size() < 2) {
    result.insert("status", QStringLiteral("error"));
    result.insert("message",
                  QStringLiteral("В файле меньше двух корректных узлов"));
    return result;
  }
  parsed.insert("status", QStringLiteral("ok"));
  return parsed;
}
