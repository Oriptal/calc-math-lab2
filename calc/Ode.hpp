#pragma once

#include <functional>
#include <vector>

namespace ode {

using Func = std::function<double(double x, double y)>;
using Exact = std::function<double(double x)>;

enum class Method { ImprovedEuler, RungeKutta4, Milne };

enum class Status {
  Ok,
  BadInterval,
  BadStep,
  StepTooLarge,
  BadTolerance,
  TooFewNodes,
  TooManyNodes
};

struct OdeEquation {
  int id = 0;
  Func f;
  std::function<Exact(double x0, double y0)> makeExact;
};

struct Node {
  double x = 0.0;
  double yExact = 0.0;
  double yImprovedEuler = 0.0;
  double yRungeKutta4 = 0.0;
  double yMilne = 0.0;
};

struct MethodSummary {
  Method method = Method::ImprovedEuler;
  int order = 2;
  bool usesRunge = true;
  double rungeError = 0.0;
  double exactError = 0.0;
  int steps = 0;
  double refinedStep = 0.0;
  int refinedSteps = 0;
  double refinedError = 0.0;
};

struct Result {
  Status status = Status::Ok;
  double x0 = 0.0;
  double xn = 0.0;
  double h = 0.0;
  double eps = 0.0;
  std::vector<Node> table;
  MethodSummary improvedEuler;
  MethodSummary rungeKutta4;
  MethodSummary milne;
};

constexpr int kMinSteps = 4;
constexpr int kMaxSteps = 100000;
constexpr int kMaxCorrectorIters = 20;
constexpr int kMaxRefineHalvings = 20;

const std::vector<OdeEquation> &equations();
const char *equationTitle(int id);
bool equationExists(int id);

std::vector<double> solveImprovedEuler(const Func &f, double x0, double y0,
                                       double h, int steps);
std::vector<double> solveRungeKutta4(const Func &f, double x0, double y0,
                                     double h, int steps);
std::vector<double> solveMilne(const Func &f, double x0, double y0, double h,
                               int steps, double eps);

int methodOrder(Method m);

double rungeEndpointError(Method m, const Func &f, double x0, double y0,
                          double h, int steps);
double refineStepByRunge(Method m, const Func &f, double x0, double y0,
                         double h0, double xn, double eps, double &outStep,
                         int &outSteps);

Result solveCauchy(int equationId, double x0, double y0, double xn, double h,
                   double eps);

const char *methodKey(Method m);
const char *methodTitle(Method m);

} // namespace ode
