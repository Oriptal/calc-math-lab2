#pragma once

#include <cstddef>
#include <string>
#include <vector>

namespace interp {

enum class Method {
  Lagrange,
  NewtonForward,
  NewtonBackward,
  GaussI,
  GaussII,
  Stirling,
  Bessel
};

enum class Status { Ok, NotEquidistant, TooFew, Duplicate };

struct Point {
  double x = 0.0;
  double y = 0.0;
};

struct MethodResult {
  Method method = Method::Lagrange;
  Status status = Status::Ok;
  double value = 0.0;
  double t = 0.0;
  int center = 0;
  int order = 0;
  std::string note;
};

constexpr std::size_t kMinPoints = 2;
constexpr std::size_t kMaxPoints = 30;

bool isEquidistant(const std::vector<Point> &nodes, double &h);

std::vector<std::vector<double>>
finiteDifferences(const std::vector<Point> &nodes);

double lagrange(const std::vector<Point> &nodes, double X);

MethodResult run(Method method, const std::vector<Point> &nodes, double X);

const char *methodKey(Method m);
const char *methodTitle(Method m);

} // namespace interp
