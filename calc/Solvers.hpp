#pragma once
#include <functional>

using MathFunc = std::function<double(double)>;

class Solver {
protected:
  double EPS;

public:
  Solver(double EPS) : EPS(EPS) {};
  virtual ~Solver() = default;
  virtual double solve(MathFunc f, double a, double b) = 0;
  double df(MathFunc f, double x);
  double d2f(MathFunc f, double x);
};

class DihotomiaSolver : public Solver {
public:
  DihotomiaSolver(double EPS) : Solver(EPS) {};
  double solve(MathFunc f, double a, double b) override;
};

class NewtonSolver : public Solver {
public:
  NewtonSolver(double EPS) : Solver(EPS) {};
  double solve(MathFunc f, double a, double b) override;
};

class IterSolver : public Solver {
public:
  IterSolver(double EPS) : Solver(EPS) {};
  double solve(MathFunc f, double a, double b) override;
};
