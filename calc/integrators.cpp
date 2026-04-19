#include "Integrators.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

namespace Integrators {

double integrateLeftRect(const IntegrandFunc &f, double a, double b, int n) {
  if (n <= 0) {
    return std::numeric_limits<double>::quiet_NaN();
  }
  const double h = (b - a) / static_cast<double>(n);
  double sum = 0.0;
  for (int i = 0; i < n; ++i) {
    const double x = a + i * h;
    sum += f(x);
  }
  return sum * h;
}

double integrateRightRect(const IntegrandFunc &f, double a, double b, int n) {
  if (n <= 0) {
    return std::numeric_limits<double>::quiet_NaN();
  }
  const double h = (b - a) / static_cast<double>(n);
  double sum = 0.0;
  for (int i = 1; i <= n; ++i) {
    const double x = a + i * h;
    sum += f(x);
  }
  return sum * h;
}

double integrateMidRect(const IntegrandFunc &f, double a, double b, int n) {
  if (n <= 0) {
    return std::numeric_limits<double>::quiet_NaN();
  }
  const double h = (b - a) / static_cast<double>(n);
  double sum = 0.0;
  for (int i = 0; i < n; ++i) {
    const double x = a + (i + 0.5) * h;
    sum += f(x);
  }
  return sum * h;
}

double integrateTrapezoid(const IntegrandFunc &f, double a, double b, int n) {
  if (n <= 0) {
    return std::numeric_limits<double>::quiet_NaN();
  }
  const double h = (b - a) / static_cast<double>(n);
  double sum = 0.5 * (f(a) + f(b));
  for (int i = 1; i < n; ++i) {
    const double x = a + i * h;
    sum += f(x);
  }
  return sum * h;
}

double integrateSimpson(const IntegrandFunc &f, double a, double b, int n) {
  if (n <= 0 || n % 2 != 0) {
    return std::numeric_limits<double>::quiet_NaN();
  }
  const double h = (b - a) / static_cast<double>(n);
  double sum = f(a) + f(b);
  for (int i = 1; i < n; ++i) {
    const double x = a + i * h;
    sum += (i % 2 == 0 ? 2.0 : 4.0) * f(x);
  }
  return sum * h / 3.0;
}

double applyMethod(IntegrationMethod method, const IntegrandFunc &f, double a,
                   double b, int n) {
  switch (method) {
  case IntegrationMethod::LeftRect:
    return integrateLeftRect(f, a, b, n);
  case IntegrationMethod::RightRect:
    return integrateRightRect(f, a, b, n);
  case IntegrationMethod::MidRect:
    return integrateMidRect(f, a, b, n);
  case IntegrationMethod::Trapezoid:
    return integrateTrapezoid(f, a, b, n);
  case IntegrationMethod::Simpson:
    return integrateSimpson(f, a, b, n);
  }
  return std::numeric_limits<double>::quiet_NaN();
}

int methodOrder(IntegrationMethod method) {
  return method == IntegrationMethod::Simpson ? 4 : 2;
}

IntegrationResult rungeSolve(IntegrationMethod method, const IntegrandFunc &f,
                             double a, double b, double eps) {
  IntegrationResult result;
  const int k = methodOrder(method);
  const double denom = std::pow(2.0, k) - 1.0;

  int n = kInitialN;
  double prev = applyMethod(method, f, a, b, n);
  if (!std::isfinite(prev)) {
    result.status = "diverges";
    result.message = "Начальное значение интеграла не конечно.";
    result.value = std::numeric_limits<double>::quiet_NaN();
    result.n = n;
    return result;
  }

  while (n * 2 <= kMaxN) {
    const int nNew = n * 2;
    const double cur = applyMethod(method, f, a, b, nNew);
    if (!std::isfinite(cur)) {
      result.status = "diverges";
      result.message = "Значение интеграла не конечно.";
      result.value = std::numeric_limits<double>::quiet_NaN();
      result.n = nNew;
      return result;
    }
    const double runge = std::abs(cur - prev) / denom;
    if (runge <= eps) {
      result.status = "ok";
      result.value = cur;
      result.n = nNew;
      result.runge_error = runge;
      return result;
    }
    prev = cur;
    n = nNew;
  }

  result.status = "max_iter";
  result.message = "Достигнут лимит разбиений.";
  result.value = prev;
  result.n = n;
  result.runge_error = std::numeric_limits<double>::infinity();
  return result;
}

namespace {

struct LimitResult {
  double value = 0.0;
  int n = 0;
  double runge_error = 0.0;
  std::string status;  // "ok" | "diverges" | "indeterminate"
};

// Iterative shrinking toward a discontinuity at `c`, integrating the piece
// towards `other`. `side = +1` → right-sided limit (interval [c+σ, other]);
// `side = -1` → left-sided limit (interval [other, c-σ]).
LimitResult limitAtEndpoint(IntegrationMethod method, const IntegrandFunc &f,
                            double c, double other, int side, double eps) {
  LimitResult res;
  const double span = std::abs(other - c);
  const double d0 = span * 1e-2;
  const double r = 0.5;
  constexpr int kMaxShrinks = 50;
  constexpr int kNeedStable = 2;
  constexpr double kBigThreshold = 1e15;
  const double stableTol = std::max(eps, eps * 3.0);

  double prevI = std::numeric_limits<double>::quiet_NaN();
  int stableCount = 0;
  double lastValue = 0.0;
  int lastN = 0;
  double lastRunge = 0.0;

  for (int kStep = 0; kStep < kMaxShrinks; ++kStep) {
    const double sigma = d0 * std::pow(r, kStep);
    double lo, hi;
    if (side > 0) {
      lo = c + sigma;
      hi = other;
    } else {
      lo = other;
      hi = c - sigma;
    }
    if (!(lo < hi)) {
      res.status = "indeterminate";
      res.value = lastValue;
      res.n = lastN;
      return res;
    }

    IntegrationResult inner = rungeSolve(method, f, lo, hi, eps);
    if (inner.status == "diverges" || !std::isfinite(inner.value)) {
      res.status = "diverges";
      res.value = std::numeric_limits<double>::quiet_NaN();
      res.n = inner.n;
      return res;
    }
    if (std::abs(inner.value) > kBigThreshold) {
      res.status = "diverges";
      res.value = std::numeric_limits<double>::quiet_NaN();
      res.n = inner.n;
      return res;
    }
    lastValue = inner.value;
    lastN = inner.n;
    lastRunge = inner.runge_error;

    // Stability check only counts when the inner integration truly
    // converged (not "max_iter"). If the method hits the subdivision
    // ceiling, any apparent plateau is a numerical artefact.
    if (std::isfinite(prevI) && inner.status == "ok") {
      const double diff = std::abs(inner.value - prevI);
      if (diff < stableTol) {
        ++stableCount;
        if (stableCount >= kNeedStable) {
          res.status = "ok";
          res.value = inner.value;
          res.n = inner.n;
          res.runge_error = lastRunge;
          return res;
        }
      } else {
        stableCount = 0;
      }
    } else {
      stableCount = 0;
    }
    prevI = inner.status == "ok" ? inner.value
                                 : std::numeric_limits<double>::quiet_NaN();
  }

  res.status = "indeterminate";
  res.value = lastValue;
  res.n = lastN;
  res.runge_error = lastRunge;
  return res;
}

bool isAntisymmetric(const IntegrandFunc &f, double c, double d,
                     double tol = 1e-6) {
  const int samples = 10;
  double worst = 0.0;
  for (int i = 0; i < samples; ++i) {
    const double t = static_cast<double>(i) / static_cast<double>(samples - 1);
    const double delta = d * std::pow(1e-3, 1.0 - t) * std::pow(0.99, t);
    const double fp = f(c + delta);
    const double fm = f(c - delta);
    if (!std::isfinite(fp) || !std::isfinite(fm)) {
      return false;
    }
    const double denom = std::max({std::abs(fp), std::abs(fm), 1e-30});
    const double diff = std::abs(fp + fm) / denom;
    if (diff > worst) {
      worst = diff;
    }
  }
  return worst < tol;
}

// Compute one segment (plain or improper) via standard handling.
struct SegmentResult {
  double value = 0.0;
  int n = 0;
  double runge_error = 0.0;
  std::string status;  // "ok" | "diverges" | "indeterminate" | "max_iter"
  std::string message;
};

SegmentResult computeSegmentStandard(IntegrationMethod method,
                                     const IntegrandFunc &f,
                                     const IntervalSegment &seg, double eps) {
  SegmentResult r;
  if (!seg.limit_at_from && !seg.limit_at_to) {
    IntegrationResult inner = rungeSolve(method, f, seg.from, seg.to, eps);
    r.value = inner.value;
    r.n = inner.n;
    r.runge_error = inner.runge_error;
    r.status = inner.status;
    r.message = inner.message;
    return r;
  }

  if (seg.limit_at_from && seg.limit_at_to) {
    const double mid = (seg.from + seg.to) / 2.0;
    LimitResult lr1 = limitAtEndpoint(method, f, seg.from, mid, +1, eps);
    if (lr1.status != "ok") {
      r.status = lr1.status;
      return r;
    }
    LimitResult lr2 = limitAtEndpoint(method, f, seg.to, mid, -1, eps);
    if (lr2.status != "ok") {
      r.status = lr2.status;
      return r;
    }
    r.value = lr1.value + lr2.value;
    r.n = lr1.n + lr2.n;
    r.runge_error = lr1.runge_error + lr2.runge_error;
    r.status = "ok";
    return r;
  }
  if (seg.limit_at_from) {
    LimitResult lr = limitAtEndpoint(method, f, seg.from, seg.to, +1, eps);
    r.value = lr.value;
    r.n = lr.n;
    r.runge_error = lr.runge_error;
    r.status = lr.status;
    return r;
  }
  LimitResult lr = limitAtEndpoint(method, f, seg.to, seg.from, -1, eps);
  r.value = lr.value;
  r.n = lr.n;
  r.runge_error = lr.runge_error;
  r.status = lr.status;
  return r;
}

}  // namespace

IntervalPlan prepareIntervals(double a, double b,
                              const std::vector<double> &discontinuities,
                              const IntegrandFunc &f, double eps) {
  (void)f;
  (void)eps;
  IntervalPlan plan;
  plan.status = "ok";

  std::vector<double> innerPoints;
  bool startIsSingular = false;
  bool endIsSingular = false;

  for (double c : discontinuities) {
    if (!std::isfinite(c)) {
      continue;
    }
    if (std::abs(c - a) < 1e-15) {
      startIsSingular = true;
    } else if (std::abs(c - b) < 1e-15) {
      endIsSingular = true;
    } else if (c > a && c < b) {
      innerPoints.push_back(c);
    }
  }
  std::sort(innerPoints.begin(), innerPoints.end());

  if (innerPoints.empty()) {
    IntervalSegment seg;
    seg.from = a;
    seg.to = b;
    seg.limit_at_from = startIsSingular;
    seg.limit_at_to = endIsSingular;
    plan.segments.push_back(seg);
    return plan;
  }

  double prev = a;
  bool prevSingular = startIsSingular;
  for (double c : innerPoints) {
    IntervalSegment seg;
    seg.from = prev;
    seg.to = c;
    seg.limit_at_from = prevSingular;
    seg.limit_at_to = true;
    plan.segments.push_back(seg);
    prev = c;
    prevSingular = true;
  }
  IntervalSegment tail;
  tail.from = prev;
  tail.to = b;
  tail.limit_at_from = prevSingular;
  tail.limit_at_to = endIsSingular;
  plan.segments.push_back(tail);
  return plan;
}

namespace {

// Try Cauchy principal value by pairing adjacent segments sharing an
// internal singular point. Returns whether PV was applied successfully for
// every singular internal point.
struct PvOutcome {
  bool success = false;
  bool usedPV = false;
  double value = 0.0;
  int n = 0;
  double runge_error = 0.0;
  std::string message;
};

PvOutcome tryPrincipalValue(IntegrationMethod method, const IntegrandFunc &f,
                            const IntervalPlan &plan, double eps) {
  PvOutcome out;
  double acc = 0.0;
  int nAcc = 0;
  double rg = 0.0;
  bool usedPV = false;

  size_t i = 0;
  while (i < plan.segments.size()) {
    const IntervalSegment &seg = plan.segments[i];

    if (!seg.limit_at_from && !seg.limit_at_to) {
      IntegrationResult inner = rungeSolve(method, f, seg.from, seg.to, eps);
      if (inner.status != "ok") {
        out.message = "Подотрезок не сошёлся.";
        return out;
      }
      acc += inner.value;
      nAcc += inner.n;
      rg += inner.runge_error;
      ++i;
      continue;
    }

    // Try pairing with next segment around shared internal discontinuity.
    bool handled = false;
    if (i + 1 < plan.segments.size()) {
      const IntervalSegment &nxt = plan.segments[i + 1];
      if (seg.limit_at_to && nxt.limit_at_from &&
          std::abs(seg.to - nxt.from) < 1e-15) {
        const double c = seg.to;
        const double leftLen = c - seg.from;
        const double rightLen = nxt.to - c;
        const double d = std::min(leftLen, rightLen);

        if (d > 0.0 && isAntisymmetric(f, c, d)) {
          double leftTailVal = 0.0;
          int leftTailN = 0;
          double leftTailRunge = 0.0;
          if (leftLen > d + 1e-15) {
            if (seg.limit_at_from) {
              LimitResult lr =
                  limitAtEndpoint(method, f, seg.from, c - d, +1, eps);
              if (lr.status != "ok") {
                out.message = "Хвостовой подотрезок расходится.";
                return out;
              }
              leftTailVal = lr.value;
              leftTailN = lr.n;
              leftTailRunge = lr.runge_error;
            } else {
              IntegrationResult inner =
                  rungeSolve(method, f, seg.from, c - d, eps);
              if (inner.status != "ok") {
                out.message = "Хвостовой подотрезок не сошёлся.";
                return out;
              }
              leftTailVal = inner.value;
              leftTailN = inner.n;
              leftTailRunge = inner.runge_error;
            }
          }

          double rightTailVal = 0.0;
          int rightTailN = 0;
          double rightTailRunge = 0.0;
          if (rightLen > d + 1e-15) {
            if (nxt.limit_at_to) {
              LimitResult lr =
                  limitAtEndpoint(method, f, nxt.to, c + d, -1, eps);
              if (lr.status != "ok") {
                out.message = "Хвостовой подотрезок расходится.";
                return out;
              }
              rightTailVal = lr.value;
              rightTailN = lr.n;
              rightTailRunge = lr.runge_error;
            } else {
              IntegrationResult inner =
                  rungeSolve(method, f, c + d, nxt.to, eps);
              if (inner.status != "ok") {
                out.message = "Хвостовой подотрезок не сошёлся.";
                return out;
              }
              rightTailVal = inner.value;
              rightTailN = inner.n;
              rightTailRunge = inner.runge_error;
            }
          }

          acc += leftTailVal + rightTailVal;
          nAcc += leftTailN + rightTailN;
          rg += leftTailRunge + rightTailRunge;
          usedPV = true;
          handled = true;
          i += 2;
        }
      }
    }

    if (handled) {
      continue;
    }

    // Singular segment that did not admit PV — fall back to standard limit.
    SegmentResult sr = computeSegmentStandard(method, f, seg, eps);
    if (sr.status != "ok") {
      out.message = "Несобственный подотрезок расходится.";
      return out;
    }
    acc += sr.value;
    nAcc += sr.n;
    rg += sr.runge_error;
    ++i;
  }

  out.success = true;
  out.usedPV = usedPV;
  out.value = acc;
  out.n = nAcc;
  out.runge_error = rg;
  return out;
}

}  // namespace

IntegrationResult integrate(IntegrationMethod method, const IntegrandFunc &f,
                            double a, double b, double eps,
                            const std::vector<double> &discontinuities) {
  IntegrationResult out;
  if (!(a < b)) {
    out.status = "error";
    out.message = "Левый предел должен быть меньше правого.";
    out.value = std::numeric_limits<double>::quiet_NaN();
    return out;
  }
  if (!(eps > 0.0) || !std::isfinite(eps)) {
    out.status = "error";
    out.message = "Некорректная точность ε.";
    out.value = std::numeric_limits<double>::quiet_NaN();
    return out;
  }

  IntervalPlan plan = prepareIntervals(a, b, discontinuities, f, eps);
  const bool improper = plan.segments.size() > 1 ||
                        plan.segments.front().limit_at_from ||
                        plan.segments.front().limit_at_to;

  double total = 0.0;
  int totalN = 0;
  double totalRunge = 0.0;
  bool standardFailed = false;
  std::string failMsg;

  for (const IntervalSegment &seg : plan.segments) {
    SegmentResult sr = computeSegmentStandard(method, f, seg, eps);
    if (sr.status == "max_iter") {
      out.status = "max_iter";
      out.message = "Не удалось достичь точности за отведённые разбиения.";
      out.value = sr.value;
      out.n = sr.n;
      out.runge_error = sr.runge_error;
      return out;
    }
    if (sr.status != "ok") {
      standardFailed = true;
      failMsg = sr.status;
      break;
    }
    total += sr.value;
    totalN += sr.n;
    totalRunge += sr.runge_error;
  }

  if (!standardFailed) {
    out.status = "ok";
    out.value = total;
    out.n = totalN;
    out.runge_error = totalRunge;
    out.message = improper ? "Несобственный интеграл, сходится."
                           : "Интеграл вычислен.";
    return out;
  }

  // Try Cauchy principal value fallback.
  PvOutcome pv = tryPrincipalValue(method, f, plan, eps);
  if (!pv.success || !pv.usedPV) {
    out.status = "diverges";
    out.value = std::numeric_limits<double>::quiet_NaN();
    out.message = "Интеграл расходится.";
    return out;
  }

  out.status = "ok_principal_value";
  out.value = pv.value;
  out.n = pv.n;
  out.runge_error = pv.runge_error;
  out.message = "Несобственный интеграл, главное значение Коши.";
  return out;
}

}  // namespace Integrators
