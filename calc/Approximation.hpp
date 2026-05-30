#pragma once

#include <cstddef>
#include <optional>
#include <vector>

namespace approx {

enum class Kind { Linear, Poly2, Poly3, Exponential, Logarithmic, Power };

enum class Status {
  Ok,
  TooFew,
  TooMany,
  NonPositiveX,
  NonPositiveY,
  Degenerate
};

struct Point {
  double x = 0.0;
  double y = 0.0;
};

struct Result {
  Kind kind = Kind::Linear;
  Status status = Status::Ok;
  std::vector<double> coeffs;
  std::vector<double> phi;
  std::vector<double> eps;
  double S = 0.0;
  double delta = 0.0;
  double r2 = 0.0;
  std::optional<double> pearson;
};

class LeastSquaresApproximator {
public:
  static constexpr std::size_t kMinPoints = 4;
  static constexpr std::size_t kMaxPoints = 12;

  Result approximate(Kind kind, const std::vector<Point> &data) const;
  std::vector<Result> approximateAll(const std::vector<Point> &data) const;

  static double evaluate(const Result &r, double x);
};

} // namespace approx
