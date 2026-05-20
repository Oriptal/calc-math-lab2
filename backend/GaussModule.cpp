#include "GaussModule.hpp"

#include "BackendUtil.hpp"
#include "../calc/Gauss.hpp"

#include <QDateTime>

#include <cmath>
#include <limits>
#include <vector>

namespace {

QVariantList toVariantList(const std::vector<double> &v) {
  QVariantList out;
  out.reserve(static_cast<qsizetype>(v.size()));
  for (double x : v) {
    out.push_back(x);
  }
  return out;
}

QVariantList toVariantMatrix(const std::vector<std::vector<double>> &m) {
  QVariantList out;
  out.reserve(static_cast<qsizetype>(m.size()));
  for (const auto &row : m) {
    out.push_back(toVariantList(row));
  }
  return out;
}

bool parseDoubleField(const QVariant &v, double &out) {
  bool ok = false;
  out = parseDouble(v.toString(), &ok);
  return ok && std::isfinite(out);
}

} // namespace

QVariantMap GaussModule::solve(const QVariantMap &payload) {
  QVariantMap result;

  const int n = payload.value("size").toInt();
  if (n <= 0 || n > GaussSolver::kMaxSize) {
    result.insert("status", static_cast<qint32>(GAUSS_INVALID_SIZE));
    result.insert("message",
                  QStringLiteral("Размерность должна быть в диапазоне 1..%1.")
                      .arg(GaussSolver::kMaxSize));
    return result;
  }

  const QVariantList rowsVar = payload.value("matrix").toList();
  const QVariantList augVar = payload.value("augmentation").toList();

  if (rowsVar.size() != n || augVar.size() != n) {
    result.insert("status", static_cast<qint32>(GAUSS_INVALID_SIZE));
    result.insert("message", QStringLiteral("Несовпадение размеров входа."));
    return result;
  }

  std::vector<std::vector<double>> matrix(n, std::vector<double>(n, 0.0));
  std::vector<double> augmentation(n, 0.0);

  for (int i = 0; i < n; ++i) {
    const QVariantList row = rowsVar[i].toList();
    if (row.size() != n) {
      result.insert("status", static_cast<qint32>(GAUSS_INVALID_SIZE));
      result.insert("message",
                    QStringLiteral("Строка %1 имеет неверную длину.").arg(i + 1));
      return result;
    }
    for (int j = 0; j < n; ++j) {
      double value = 0.0;
      if (!parseDoubleField(row[j], value)) {
        result.insert("status", static_cast<qint32>(GAUSS_INVALID_SIZE));
        result.insert("message",
                      QStringLiteral("Некорректное число в a[%1,%2].")
                          .arg(i + 1)
                          .arg(j + 1));
        return result;
      }
      matrix[i][j] = value;
    }
    double bValue = 0.0;
    if (!parseDoubleField(augVar[i], bValue)) {
      result.insert("status", static_cast<qint32>(GAUSS_INVALID_SIZE));
      result.insert("message",
                    QStringLiteral("Некорректное число в b[%1].").arg(i + 1));
      return result;
    }
    augmentation[i] = bValue;
  }

  GaussSolver solver;
  const GaussResult r = solver.solve(matrix, augmentation);

  result.insert("status", static_cast<qint32>(r.status));
  result.insert("determinant",
                std::isfinite(r.determinant)
                    ? QVariant(r.determinant)
                    : QVariant(std::numeric_limits<double>::quiet_NaN()));
  result.insert("triangular", toVariantMatrix(r.triangular));
  result.insert("reducedAugmentation", toVariantList(r.reducedAugmentation));
  result.insert("solution", toVariantList(r.solution));
  result.insert("residuals", toVariantList(r.residuals));
  return result;
}

QVariantMap GaussModule::generate(qint32 size) {
  QVariantMap result;

  if (size <= 0 || size > GaussSolver::kMaxSize) {
    result.insert("status", static_cast<qint32>(GAUSS_INVALID_SIZE));
    result.insert("message",
                  QStringLiteral("Размерность должна быть в диапазоне 1..%1.")
                      .arg(GaussSolver::kMaxSize));
    return result;
  }

  const auto seed = static_cast<unsigned long long>(
      QDateTime::currentMSecsSinceEpoch() ^
      (static_cast<qint64>(size) * 0x9E3779B97F4A7C15LL));

  const auto matrix = GaussSolver::generateMatrix(size, seed);
  const auto augmentation = GaussSolver::generateAugmentation(size, seed);

  result.insert("status", static_cast<qint32>(GAUSS_SINGLE_SOLUTION));
  result.insert("matrix", toVariantMatrix(matrix));
  result.insert("augmentation", toVariantList(augmentation));
  return result;
}
