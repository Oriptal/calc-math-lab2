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

enum class Status {
  Ok,
  NotEquidistant, // конечно-разностным методам нужны равноотстоящие узлы
  TooFew,         // меньше двух узлов
  Duplicate       // совпадающие узлы x
};

struct Point {
  double x = 0.0;
  double y = 0.0;
};

struct MethodResult {
  Method method = Method::Lagrange;
  Status status = Status::Ok;
  double value = 0.0; // значение многочлена P(X)
  double t = 0.0;     // параметр t = (X − x_c) / h для конечно-разностных методов
  int center = 0;     // индекс опорного узла x_c
  int order = 0;      // число использованных разностей (степень)
  std::string note;   // нестрогая рекомендация (|t|, чётность узлов, экстраполяция)
};

// Шаг равномерной сетки kMinPoints..kMaxPoints узлов.
constexpr std::size_t kMinPoints = 2;
constexpr std::size_t kMaxPoints = 30;

// Признак равноотстоящих узлов; при true в h записывается шаг сетки.
bool isEquidistant(const std::vector<Point> &nodes, double &h);

// Треугольная таблица конечных разностей: out[k][i] = Δᵏyᵢ, out[0] совпадает с y.
std::vector<std::vector<double>>
finiteDifferences(const std::vector<Point> &nodes);

// Значение интерполяционного многочлена Лагранжа в точке X (для любых узлов).
double lagrange(const std::vector<Point> &nodes, double X);

// Один метод с проверкой применимости.
MethodResult run(Method method, const std::vector<Point> &nodes, double X);

const char *methodKey(Method m);
const char *methodTitle(Method m);

} // namespace interp
