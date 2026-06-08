#include "Ode.hpp"

#include <algorithm>
#include <cmath>

namespace ode {

const std::vector<OdeEquation> &equations() {
  static const std::vector<OdeEquation> table = {
      {0, [](double, double y) { return y; },
       [](double x0, double y0) {
         return Exact([x0, y0](double x) { return y0 * std::exp(x - x0); });
       }},
      {1, [](double x, double y) { return x + y; },
       [](double x0, double y0) {
         const double c = y0 + x0 + 1.0;
         return Exact(
             [c, x0](double x) { return c * std::exp(x - x0) - x - 1.0; });
       }},
      {2, [](double x, double y) { return -2.0 * x * y; },
       [](double x0, double y0) {
         return Exact(
             [x0, y0](double x) { return y0 * std::exp(x0 * x0 - x * x); });
       }},
      {3, [](double x, double y) { return x - y; },
       [](double x0, double y0) {
         const double c = y0 - x0 + 1.0;
         return Exact(
             [c, x0](double x) { return c * std::exp(x0 - x) + x - 1.0; });
       }},
  };
  return table;
}

bool equationExists(int id) {
  return id >= 0 && id < static_cast<int>(equations().size());
}

const char *equationTitle(int id) {
  switch (id) {
  case 0:
    return "y′ = y";
  case 1:
    return "y′ = x + y";
  case 2:
    return "y′ = −2xy";
  case 3:
    return "y′ = x − y";
  }
  return "";
}

std::vector<double> solveImprovedEuler(const Func &f, double x0, double y0,
                                       double h, int steps) {
  std::vector<double> y(static_cast<std::size_t>(steps) + 1);
  y[0] = y0;
  for (int i = 0; i < steps; ++i) {
    const double xi = x0 + i * h;
    const double fi = f(xi, y[i]);
    const double predictor = y[i] + h * fi;
    y[i + 1] = y[i] + 0.5 * h * (fi + f(xi + h, predictor));
  }
  return y;
}

std::vector<double> solveRungeKutta4(const Func &f, double x0, double y0,
                                     double h, int steps) {
  std::vector<double> y(static_cast<std::size_t>(steps) + 1);
  y[0] = y0;
  for (int i = 0; i < steps; ++i) {
    const double xi = x0 + i * h;
    const double k1 = h * f(xi, y[i]);
    const double k2 = h * f(xi + 0.5 * h, y[i] + 0.5 * k1);
    const double k3 = h * f(xi + 0.5 * h, y[i] + 0.5 * k2);
    const double k4 = h * f(xi + h, y[i] + k3);
    y[i + 1] = y[i] + (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
  }
  return y;
}

std::vector<double> solveMilne(const Func &f, double x0, double y0, double h,
                               int steps, double eps) {
  std::vector<double> y(static_cast<std::size_t>(steps) + 1);
  std::vector<double> fv(static_cast<std::size_t>(steps) + 1);

  const int boot = std::min(steps, 3);
  const std::vector<double> start = solveRungeKutta4(f, x0, y0, h, boot);
  for (int i = 0; i <= boot; ++i) {
    y[i] = start[i];
    fv[i] = f(x0 + i * h, y[i]);
  }

  for (int i = 4; i <= steps; ++i) {
    const double xi = x0 + i * h;
    const double yPred =
        y[i - 4] +
        (4.0 * h / 3.0) * (2.0 * fv[i - 3] - fv[i - 2] + 2.0 * fv[i - 1]);
    double yCur = yPred;
    for (int it = 0; it < kMaxCorrectorIters; ++it) {
      const double yCorr =
          y[i - 2] + (h / 3.0) * (fv[i - 2] + 4.0 * fv[i - 1] + f(xi, yCur));
      const bool done = std::abs(yCorr - yCur) < eps;
      yCur = yCorr;
      if (done) {
        break;
      }
    }
    y[i] = yCur;
    fv[i] = f(xi, yCur);
  }
  return y;
}

int methodOrder(Method m) {
  switch (m) {
  case Method::ImprovedEuler:
    return 2;
  case Method::RungeKutta4:
    return 4;
  case Method::Milne:
    return 4;
  }
  return 1;
}

namespace {

double solveEndpoint(Method m, const Func &f, double x0, double y0, double h,
                     int steps) {
  std::vector<double> y;
  switch (m) {
  case Method::ImprovedEuler:
    y = solveImprovedEuler(f, x0, y0, h, steps);
    break;
  case Method::RungeKutta4:
    y = solveRungeKutta4(f, x0, y0, h, steps);
    break;
  case Method::Milne:
    y = solveMilne(f, x0, y0, h, steps, 1e-12);
    break;
  }
  return y.empty() ? y0 : y.back();
}

} // namespace

double rungeEndpointError(Method m, const Func &f, double x0, double y0,
                          double h, int steps) {
  const double yH = solveEndpoint(m, f, x0, y0, h, steps);
  const double yH2 = solveEndpoint(m, f, x0, y0, h / 2.0, steps * 2);
  const double denom = std::pow(2.0, methodOrder(m)) - 1.0;
  return std::abs(yH - yH2) / denom;
}

double refineStepByRunge(Method m, const Func &f, double x0, double y0,
                         double h0, double xn, double eps, double &outStep,
                         int &outSteps) {
  double h = h0;
  int steps = static_cast<int>(std::lround((xn - x0) / h));
  if (steps < 1) {
    steps = 1;
  }
  double r = rungeEndpointError(m, f, x0, y0, h, steps);
  int guard = 0;
  while (r > eps && guard < kMaxRefineHalvings && steps * 2 <= kMaxSteps) {
    h *= 0.5;
    steps *= 2;
    r = rungeEndpointError(m, f, x0, y0, h, steps);
    ++guard;
  }
  outStep = h;
  outSteps = steps;
  return r;
}

namespace {

MethodSummary makeSummary(Method m, const Func &f, double x0, double y0,
                          double xn, double h, double eps, int steps,
                          double exactError) {
  MethodSummary s;
  s.method = m;
  s.order = methodOrder(m);
  s.steps = steps;
  s.exactError = exactError;
  s.usesRunge = m != Method::Milne;
  if (s.usesRunge) {
    s.rungeError = rungeEndpointError(m, f, x0, y0, h, steps);
    s.refinedError = refineStepByRunge(m, f, x0, y0, h, xn, eps, s.refinedStep,
                                       s.refinedSteps);
  }
  return s;
}

} // namespace

Result solveCauchy(int equationId, double x0, double y0, double xn, double h,
                   double eps) {
  Result res;
  res.x0 = x0;
  res.xn = xn;
  res.h = h;
  res.eps = eps;

  if (!equationExists(equationId)) {
    res.status = Status::BadInterval;
    return res;
  }
  if (!(xn > x0)) {
    res.status = Status::BadInterval;
    return res;
  }
  if (!(h > 0.0)) {
    res.status = Status::BadStep;
    return res;
  }
  const double span = xn - x0;
  if (h > span + 1e-12) {
    res.status = Status::StepTooLarge;
    return res;
  }
  if (!(eps > 0.0)) {
    res.status = Status::BadTolerance;
    return res;
  }

  int steps = static_cast<int>(std::lround(span / h));
  if (steps < 1) {
    steps = 1;
  }
  if (steps > kMaxSteps) {
    res.status = Status::TooManyNodes;
    return res;
  }
  if (steps < kMinSteps) {
    res.status = Status::TooFewNodes;
    return res;
  }

  const OdeEquation &eq = equations()[static_cast<std::size_t>(equationId)];
  const Func &f = eq.f;
  const Exact exact = eq.makeExact(x0, y0);

  const std::vector<double> yIE = solveImprovedEuler(f, x0, y0, h, steps);
  const std::vector<double> yRK = solveRungeKutta4(f, x0, y0, h, steps);
  const std::vector<double> yMl = solveMilne(f, x0, y0, h, steps, eps);

  res.table.resize(static_cast<std::size_t>(steps) + 1);
  double errIE = 0.0;
  double errRK = 0.0;
  double errMl = 0.0;
  for (int i = 0; i <= steps; ++i) {
    const double xi = x0 + i * h;
    const double ye = exact(xi);
    Node &nd = res.table[static_cast<std::size_t>(i)];
    nd.x = xi;
    nd.yExact = ye;
    nd.yImprovedEuler = yIE[i];
    nd.yRungeKutta4 = yRK[i];
    nd.yMilne = yMl[i];
    errIE = std::max(errIE, std::abs(ye - yIE[i]));
    errRK = std::max(errRK, std::abs(ye - yRK[i]));
    errMl = std::max(errMl, std::abs(ye - yMl[i]));
  }

  res.improvedEuler =
      makeSummary(Method::ImprovedEuler, f, x0, y0, xn, h, eps, steps, errIE);
  res.rungeKutta4 =
      makeSummary(Method::RungeKutta4, f, x0, y0, xn, h, eps, steps, errRK);
  res.milne = makeSummary(Method::Milne, f, x0, y0, xn, h, eps, steps, errMl);

  res.status = Status::Ok;
  return res;
}

const char *methodKey(Method m) {
  switch (m) {
  case Method::ImprovedEuler:
    return "improved_euler";
  case Method::RungeKutta4:
    return "rk4";
  case Method::Milne:
    return "milne";
  }
  return "";
}

const char *methodTitle(Method m) {
  switch (m) {
  case Method::ImprovedEuler:
    return "Усоверш. метод Эйлера";
  case Method::RungeKutta4:
    return "Метод Рунге-Кутта 4";
  case Method::Milne:
    return "Метод Милна";
  }
  return "";
}

} // namespace ode
