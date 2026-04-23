#pragma once

#include <functional>
#include <string>
#include <vector>

using IntegrandFunc = std::function<double(double)>;

struct IntegrationResult {
  double value = 0.0;
  int n = 0;
  double runge_error = 0.0;
  std::string status;
  std::string message;
};

class Integrator {
protected:
  double EPS;

public:
  static constexpr int kInitialN = 4;
  static constexpr int kMaxN = 1 << 20;

  Integrator(double EPS) : EPS(EPS) {};
  virtual ~Integrator() = default;

  virtual double apply(IntegrandFunc f, double a, double b, int n) = 0;
  virtual int order() = 0;

  IntegrationResult rungeSolve(IntegrandFunc f, double a, double b);
  IntegrationResult integrate(IntegrandFunc f, double a, double b,
                              const std::vector<double> &discontinuities);
};

class LeftRectIntegrator : public Integrator {
public:
  LeftRectIntegrator(double EPS) : Integrator(EPS) {};
  double apply(IntegrandFunc f, double a, double b, int n) override;
  int order() override { return 2; }
};

class RightRectIntegrator : public Integrator {
public:
  RightRectIntegrator(double EPS) : Integrator(EPS) {};
  double apply(IntegrandFunc f, double a, double b, int n) override;
  int order() override { return 2; }
};

class MidRectIntegrator : public Integrator {
public:
  MidRectIntegrator(double EPS) : Integrator(EPS) {};
  double apply(IntegrandFunc f, double a, double b, int n) override;
  int order() override { return 2; }
};

class TrapezoidIntegrator : public Integrator {
public:
  TrapezoidIntegrator(double EPS) : Integrator(EPS) {};
  double apply(IntegrandFunc f, double a, double b, int n) override;
  int order() override { return 2; }
};

class SimpsonIntegrator : public Integrator {
public:
  SimpsonIntegrator(double EPS) : Integrator(EPS) {};
  double apply(IntegrandFunc f, double a, double b, int n) override;
  int order() override { return 4; }
};
