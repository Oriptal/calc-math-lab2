#pragma once

#include <cmath>
#include <functional>
#include <string>
#include <vector>

using IntegrandFunc = std::function<double(double)>;

enum class IntegrationMethod {
  LeftRect = 0,
  RightRect = 1,
  MidRect = 2,
  Trapezoid = 3,
  Simpson = 4,
};

struct IntegrationResult {
  double value = 0.0;
  int n = 0;
  double runge_error = 0.0;
  std::string status;  // "ok" | "ok_principal_value" | "diverges" | "indeterminate" | "max_iter" | "error"
  std::string message;
};

struct IntervalSegment {
  double from = 0.0;
  double to = 0.0;
  bool limit_at_from = false;
  bool limit_at_to = false;
};

struct IntervalPlan {
  std::string status;  // "ok" | "ok_principal_value" | "diverges" | "indeterminate"
  std::string message;
  std::vector<IntervalSegment> segments;
};

namespace Integrators {

constexpr int kInitialN = 4;
constexpr int kMaxN = 1 << 20;

double integrateLeftRect(const IntegrandFunc &f, double a, double b, int n);
double integrateRightRect(const IntegrandFunc &f, double a, double b, int n);
double integrateMidRect(const IntegrandFunc &f, double a, double b, int n);
double integrateTrapezoid(const IntegrandFunc &f, double a, double b, int n);
double integrateSimpson(const IntegrandFunc &f, double a, double b, int n);

double applyMethod(IntegrationMethod method, const IntegrandFunc &f, double a,
                   double b, int n);
int methodOrder(IntegrationMethod method);

IntegrationResult rungeSolve(IntegrationMethod method, const IntegrandFunc &f,
                             double a, double b, double eps);

IntervalPlan prepareIntervals(double a, double b,
                              const std::vector<double> &discontinuities,
                              const IntegrandFunc &f, double eps);

IntegrationResult integrate(IntegrationMethod method, const IntegrandFunc &f,
                            double a, double b, double eps,
                            const std::vector<double> &discontinuities);

}  // namespace Integrators
