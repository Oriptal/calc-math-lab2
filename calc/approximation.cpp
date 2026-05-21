#include "Approximation.hpp"

#include "Gauss.hpp"

#include <cmath>

namespace approx {

namespace {

constexpr double kEps = 1e-12;

double phiAt(Kind kind, const std::vector<double> &a, double x) {
  switch (kind) {
  case Kind::Linear:
    return a[0] * x + a[1];
  case Kind::Poly2:
    return a[0] + a[1] * x + a[2] * x * x;
  case Kind::Poly3:
    return a[0] + a[1] * x + a[2] * x * x + a[3] * x * x * x;
  case Kind::Exponential:
    return a[0] * std::exp(a[1] * x);
  case Kind::Logarithmic:
    return a[0] * std::log(x) + a[1];
  case Kind::Power:
    return a[0] * std::pow(x, a[1]);
  }
  return 0.0;
}

double computeR2(const std::vector<double> &y, const std::vector<double> &phi) {
  if (y.size() != phi.size() || y.empty()) {
    return 0.0;
  }
  double meanY = 0.0;
  for (double v : y) {
    meanY += v;
  }
  meanY /= static_cast<double>(y.size());

  double ssRes = 0.0;
  double ssTot = 0.0;
  for (std::size_t i = 0; i < y.size(); ++i) {
    ssRes += (y[i] - phi[i]) * (y[i] - phi[i]);
    ssTot += (y[i] - meanY) * (y[i] - meanY);
  }
  if (ssTot < kEps) {
    return ssRes < kEps ? 1.0 : 0.0;
  }
  return 1.0 - ssRes / ssTot;
}

double computePearson(const std::vector<double> &x,
                      const std::vector<double> &y) {
  if (x.size() != y.size() || x.empty()) {
    return 0.0;
  }
  double mx = 0.0;
  double my = 0.0;
  for (double v : x) {
    mx += v;
  }
  for (double v : y) {
    my += v;
  }
  mx /= static_cast<double>(x.size());
  my /= static_cast<double>(y.size());

  double num = 0.0;
  double denomX = 0.0;
  double denomY = 0.0;
  for (std::size_t i = 0; i < x.size(); ++i) {
    const double dx = x[i] - mx;
    const double dy = y[i] - my;
    num += dx * dy;
    denomX += dx * dx;
    denomY += dy * dy;
  }
  const double denom = std::sqrt(denomX * denomY);
  if (denom < kEps) {
    return 0.0;
  }
  return num / denom;
}

void fillResidualsAndStats(Result &res, const std::vector<Point> &data,
                           const std::vector<double> &coeffs) {
  const std::size_t n = data.size();
  res.phi.assign(n, 0.0);
  res.eps.assign(n, 0.0);
  std::vector<double> ys(n);
  for (std::size_t i = 0; i < n; ++i) {
    res.phi[i] = phiAt(res.kind, coeffs, data[i].x);
    res.eps[i] = res.phi[i] - data[i].y;
    ys[i] = data[i].y;
  }

  double S = 0.0;
  for (double e : res.eps) {
    S += e * e;
  }
  res.S = S;
  res.delta = std::sqrt(S / static_cast<double>(n));
  res.r2 = computeR2(ys, res.phi);
}

struct LinearFit {
  bool ok = false;
  double slope = 0.0;
  double intercept = 0.0;
};

// Линейная регрессия по правилу Крамера в координатах (xs, ys):
// решает aSXX + bSX = SXY, aSX + bn = SY относительно (a — наклон, b —
// свободный член), возвращая ok=false при вырожденной системе.
LinearFit linearCramer(const std::vector<double> &xs,
                       const std::vector<double> &ys) {
  LinearFit out;
  const std::size_t n = xs.size();
  if (n == 0 || n != ys.size()) {
    return out;
  }

  double SX = 0.0;
  double SXX = 0.0;
  double SY = 0.0;
  double SXY = 0.0;
  for (std::size_t i = 0; i < n; ++i) {
    SX += xs[i];
    SXX += xs[i] * xs[i];
    SY += ys[i];
    SXY += xs[i] * ys[i];
  }

  const double nD = static_cast<double>(n);
  const double det = SXX * nD - SX * SX;
  if (std::abs(det) < kEps) {
    return out;
  }
  const double d1 = SXY * nD - SX * SY;
  const double d2 = SXX * SY - SX * SXY;
  out.ok = true;
  out.slope = d1 / det;
  out.intercept = d2 / det;
  return out;
}

Result fitLinear(const std::vector<Point> &data) {
  Result res;
  res.kind = Kind::Linear;

  std::vector<double> xs;
  std::vector<double> ys;
  xs.reserve(data.size());
  ys.reserve(data.size());
  for (const auto &p : data) {
    xs.push_back(p.x);
    ys.push_back(p.y);
  }

  const LinearFit fit = linearCramer(xs, ys);
  if (!fit.ok) {
    res.status = Status::Degenerate;
    return res;
  }

  res.coeffs = {fit.slope, fit.intercept};
  fillResidualsAndStats(res, data, res.coeffs);
  res.pearson = computePearson(xs, ys);
  return res;
}

Result fitPolyKind(Kind kind, int degree, const std::vector<Point> &data) {
  Result res;
  res.kind = kind;

  const int m = degree + 1;
  // Степенные суммы x^k нужны до 2*degree включительно.
  std::vector<double> sumPow(2 * degree + 1, 0.0);
  std::vector<double> sumXky(m, 0.0);

  for (const auto &p : data) {
    double xp = 1.0;
    for (int k = 0; k <= 2 * degree; ++k) {
      sumPow[k] += xp;
      if (k < m) {
        sumXky[k] += xp * p.y;
      }
      xp *= p.x;
    }
  }

  std::vector<std::vector<double>> matrix(m, std::vector<double>(m, 0.0));
  std::vector<double> rhs(m, 0.0);
  for (int j = 0; j < m; ++j) {
    for (int k = 0; k < m; ++k) {
      matrix[j][k] = sumPow[j + k];
    }
    rhs[j] = sumXky[j];
  }

  GaussSolver solver;
  const GaussResult r = solver.solve(matrix, rhs);
  if (r.status != GAUSS_SINGLE_SOLUTION) {
    res.status = Status::Degenerate;
    return res;
  }

  res.coeffs = r.solution;
  fillResidualsAndStats(res, data, res.coeffs);
  return res;
}

Result fitExponential(const std::vector<Point> &data) {
  Result res;
  res.kind = Kind::Exponential;

  for (const auto &p : data) {
    if (p.y <= kEps) {
      res.status = Status::NonPositiveY;
      return res;
    }
  }

  std::vector<double> xs;
  std::vector<double> ys;
  xs.reserve(data.size());
  ys.reserve(data.size());
  for (const auto &p : data) {
    xs.push_back(p.x);
    ys.push_back(std::log(p.y));
  }

  const LinearFit fit = linearCramer(xs, ys);
  if (!fit.ok) {
    res.status = Status::Degenerate;
    return res;
  }

  res.coeffs = {std::exp(fit.intercept), fit.slope};
  fillResidualsAndStats(res, data, res.coeffs);
  return res;
}

Result fitLogarithmic(const std::vector<Point> &data) {
  Result res;
  res.kind = Kind::Logarithmic;

  for (const auto &p : data) {
    if (p.x <= kEps) {
      res.status = Status::NonPositiveX;
      return res;
    }
  }

  std::vector<double> xs;
  std::vector<double> ys;
  xs.reserve(data.size());
  ys.reserve(data.size());
  for (const auto &p : data) {
    xs.push_back(std::log(p.x));
    ys.push_back(p.y);
  }

  const LinearFit fit = linearCramer(xs, ys);
  if (!fit.ok) {
    res.status = Status::Degenerate;
    return res;
  }

  res.coeffs = {fit.slope, fit.intercept};
  fillResidualsAndStats(res, data, res.coeffs);
  return res;
}

Result fitPower(const std::vector<Point> &data) {
  Result res;
  res.kind = Kind::Power;

  for (const auto &p : data) {
    if (p.x <= kEps) {
      res.status = Status::NonPositiveX;
      return res;
    }
    if (p.y <= kEps) {
      res.status = Status::NonPositiveY;
      return res;
    }
  }

  std::vector<double> xs;
  std::vector<double> ys;
  xs.reserve(data.size());
  ys.reserve(data.size());
  for (const auto &p : data) {
    xs.push_back(std::log(p.x));
    ys.push_back(std::log(p.y));
  }

  const LinearFit fit = linearCramer(xs, ys);
  if (!fit.ok) {
    res.status = Status::Degenerate;
    return res;
  }

  res.coeffs = {std::exp(fit.intercept), fit.slope};
  fillResidualsAndStats(res, data, res.coeffs);
  return res;
}

} // namespace

Result
LeastSquaresApproximator::approximate(Kind kind,
                                      const std::vector<Point> &data) const {
  Result res;
  res.kind = kind;

  if (data.size() < kMinPoints) {
    res.status = Status::TooFew;
    return res;
  }
  if (data.size() > kMaxPoints) {
    res.status = Status::TooMany;
    return res;
  }

  switch (kind) {
  case Kind::Linear:
    return fitLinear(data);
  case Kind::Poly2:
    return fitPolyKind(Kind::Poly2, 2, data);
  case Kind::Poly3:
    return fitPolyKind(Kind::Poly3, 3, data);
  case Kind::Exponential:
    return fitExponential(data);
  case Kind::Logarithmic:
    return fitLogarithmic(data);
  case Kind::Power:
    return fitPower(data);
  }
  return res;
}

std::vector<Result> LeastSquaresApproximator::approximateAll(
    const std::vector<Point> &data) const {
  return {
      approximate(Kind::Linear, data),
      approximate(Kind::Poly2, data),
      approximate(Kind::Poly3, data),
      approximate(Kind::Exponential, data),
      approximate(Kind::Logarithmic, data),
      approximate(Kind::Power, data),
  };
}

double LeastSquaresApproximator::evaluate(const Result &r, double x) {
  if (r.status != Status::Ok) {
    return std::nan("");
  }
  if ((r.kind == Kind::Logarithmic || r.kind == Kind::Power) && x <= kEps) {
    return std::nan("");
  }
  const double y = phiAt(r.kind, r.coeffs, x);
  return std::isfinite(y) ? y : std::nan("");
}

} // namespace approx
