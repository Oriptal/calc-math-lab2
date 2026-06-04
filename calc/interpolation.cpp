#include "Interpolation.hpp"

#include <cmath>

namespace interp {

namespace {

constexpr double kEps = 1e-9;

double factorial(int k) {
  double f = 1.0;
  for (int i = 2; i <= k; ++i) {
    f *= static_cast<double>(i);
  }
  return f;
}

// Индекс узла, ближайшего к X (для центральных схем Гаусса и Стирлинга).
int nearestIndex(const std::vector<Point> &nodes, double X) {
  int best = 0;
  double bestDist = std::abs(nodes[0].x - X);
  for (int i = 1; i < static_cast<int>(nodes.size()); ++i) {
    const double d = std::abs(nodes[i].x - X);
    if (d < bestDist) {
      bestDist = d;
      best = i;
    }
  }
  return best;
}

using Diff = std::vector<std::vector<double>>;

// Многочлен Ньютона, 1-я формула (интерполирование вперёд), опорный узел x₀.
double newtonForward(const Diff &d, const std::vector<Point> &nodes, double h,
                     double X, int &order) {
  const int n = static_cast<int>(nodes.size());
  const double t = (X - nodes[0].x) / h;
  double result = nodes[0].y;
  double factor = 1.0; // t(t−1)…(t−k+1) / k!
  order = 0;
  for (int k = 1; k <= n - 1; ++k) {
    factor *= (t - (k - 1)) / k;
    result += factor * d[k][0];
    order = k;
  }
  return result;
}

// Многочлен Ньютона, 2-я формула (интерполирование назад), опорный узел xₙ.
double newtonBackward(const Diff &d, const std::vector<Point> &nodes, double h,
                      double X, int &order) {
  const int n = static_cast<int>(nodes.size());
  const double t = (X - nodes[n - 1].x) / h;
  double result = nodes[n - 1].y;
  double factor = 1.0; // t(t+1)…(t+k−1) / k!
  order = 0;
  for (int k = 1; k <= n - 1; ++k) {
    factor *= (t + (k - 1)) / k;
    result += factor * d[k][n - 1 - k];
    order = k;
  }
  return result;
}

// 1-я формула Гаусса (x > a): зигзаг конечных разностей вверх от опорного узла.
double gaussForward(const Diff &d, const std::vector<Point> &nodes, double h,
                    double X, int c, double &t, int &order) {
  const int n = static_cast<int>(nodes.size());
  t = (X - nodes[c].x) / h;
  double result = nodes[c].y;
  double prod = 1.0;
  double fact = 1.0;
  order = 0;
  for (int k = 1;; ++k) {
    const int idx = c - k / 2; // базовый индекс для Δᵏ
    if (idx < 0 || idx + k > n - 1) {
      break;
    }
    const int half = k / 2; // для нечётных k совпадает с (k−1)/2
    const double f = (k % 2 == 1) ? (t + half) : (t - half);
    prod *= f;
    fact *= k;
    result += prod / fact * d[k][idx];
    order = k;
  }
  return result;
}

// 2-я формула Гаусса (x < a): зигзаг конечных разностей вниз от опорного узла.
double gaussBackward(const Diff &d, const std::vector<Point> &nodes, double h,
                     double X, int c, double &t, int &order) {
  const int n = static_cast<int>(nodes.size());
  t = (X - nodes[c].x) / h;
  double result = nodes[c].y;
  double prod = 1.0;
  double fact = 1.0;
  order = 0;
  for (int k = 1;; ++k) {
    const int idx = c - (k + 1) / 2;
    if (idx < 0 || idx + k > n - 1) {
      break;
    }
    const int half = k / 2; // для нечётных k совпадает с (k−1)/2
    const double f = (k % 2 == 1) ? (t - half) : (t + half);
    prod *= f;
    fact *= k;
    result += prod / fact * d[k][idx];
    order = k;
  }
  return result;
}

// Формула Стирлинга — среднее 1-й и 2-й формул Гаусса (нечётное число узлов).
double stirling(const Diff &d, const std::vector<Point> &nodes, double h,
                double X, int c, double &t, int &order) {
  const int n = static_cast<int>(nodes.size());
  t = (X - nodes[c].x) / h;
  const double t2 = t * t;
  double result = nodes[c].y;
  double p2 = 1.0; // ∏(t² − i²)
  double fact = 1.0;
  order = 0;
  for (int k = 1;; ++k) {
    fact *= k;
    if (k % 2 == 1) {
      const int j = (k + 1) / 2;
      const int idxA = c - j;
      const int idxB = c - (j - 1);
      if (idxA < 0 || idxB + k > n - 1) {
        break;
      }
      const double diff = (d[k][idxA] + d[k][idxB]) / 2.0;
      result += t * p2 / fact * diff;
    } else {
      const int j = k / 2;
      const int idx = c - j;
      if (idx < 0 || idx + k > n - 1) {
        break;
      }
      result += t2 * p2 / fact * d[k][idx];
      p2 *= (t2 - static_cast<double>(j) * static_cast<double>(j));
    }
    order = k;
  }
  return result;
}

// Формула Бесселя — интерполирование на середину (чётное число узлов).
double bessel(const Diff &d, const std::vector<Point> &nodes, double h, double X,
              int c, double &t, int &order) {
  const int n = static_cast<int>(nodes.size());
  t = (X - nodes[c].x) / h;
  double result = (d[0][c] + d[0][c + 1]) / 2.0;
  order = 0;
  if (c + 1 <= n - 1) {
    result += (t - 0.5) * d[1][c];
    order = 1;
  }
  double g = 1.0; // ∏ парных множителей G₂ⱼ
  for (int j = 1;; ++j) {
    g *= (t + (j - 1)) * (t - static_cast<double>(j));
    const int e = 2 * j;
    const int eA = c - j;
    const int eB = c - (j - 1);
    if (eA < 0 || eB + e > n - 1) {
      break;
    }
    const double diffEven = (d[e][eA] + d[e][eB]) / 2.0;
    result += g / factorial(e) * diffEven;
    order = e;
    const int o = 2 * j + 1;
    const int oA = c - j;
    if (oA < 0 || oA + o > n - 1) {
      break;
    }
    result += (t - 0.5) * g / factorial(o) * d[o][oA];
    order = o;
  }
  return result;
}

std::string rangeNote(const std::vector<Point> &nodes, double X) {
  const double lo = nodes.front().x;
  const double hi = nodes.back().x;
  if (X < lo - kEps || X > hi + kEps) {
    return "экстраполяция: точка вне [x₀, xₙ]";
  }
  return {};
}

} // namespace

bool isEquidistant(const std::vector<Point> &nodes, double &h) {
  const std::size_t n = nodes.size();
  if (n < 2) {
    h = 0.0;
    return false;
  }
  h = nodes[1].x - nodes[0].x;
  if (std::abs(h) < kEps) {
    return false;
  }
  for (std::size_t i = 1; i < n; ++i) {
    const double step = nodes[i].x - nodes[i - 1].x;
    if (std::abs(step - h) > 1e-6 * std::max(1.0, std::abs(h))) {
      return false;
    }
  }
  return true;
}

std::vector<std::vector<double>>
finiteDifferences(const std::vector<Point> &nodes) {
  const std::size_t n = nodes.size();
  std::vector<std::vector<double>> d(n);
  d[0].resize(n);
  for (std::size_t i = 0; i < n; ++i) {
    d[0][i] = nodes[i].y;
  }
  for (std::size_t k = 1; k < n; ++k) {
    d[k].resize(n - k);
    for (std::size_t i = 0; i < n - k; ++i) {
      d[k][i] = d[k - 1][i + 1] - d[k - 1][i];
    }
  }
  return d;
}

double lagrange(const std::vector<Point> &nodes, double X) {
  const std::size_t n = nodes.size();
  double sum = 0.0;
  for (std::size_t i = 0; i < n; ++i) {
    double term = nodes[i].y;
    for (std::size_t j = 0; j < n; ++j) {
      if (j == i) {
        continue;
      }
      term *= (X - nodes[j].x) / (nodes[i].x - nodes[j].x);
    }
    sum += term;
  }
  return sum;
}

MethodResult run(Method method, const std::vector<Point> &nodes, double X) {
  MethodResult r;
  r.method = method;

  const int n = static_cast<int>(nodes.size());
  if (n < static_cast<int>(kMinPoints)) {
    r.status = Status::TooFew;
    return r;
  }
  for (int i = 0; i < n; ++i) {
    for (int j = i + 1; j < n; ++j) {
      if (std::abs(nodes[i].x - nodes[j].x) < kEps) {
        r.status = Status::Duplicate;
        return r;
      }
    }
  }

  if (method == Method::Lagrange) {
    r.value = lagrange(nodes, X);
    r.order = n - 1;
    r.note = rangeNote(nodes, X);
    return r;
  }

  double h = 0.0;
  if (!isEquidistant(nodes, h)) {
    r.status = Status::NotEquidistant;
    return r;
  }
  const Diff d = finiteDifferences(nodes);

  const char *edge = "точка у края таблицы: доступна низкая степень";
  const double mid = (n - 1) / 2.0;

  switch (method) {
  case Method::NewtonForward:
    r.center = 0;
    r.t = (X - nodes[0].x) / h;
    r.value = newtonForward(d, nodes, h, X, r.order);
    if (r.t > mid) {
      r.note = "правая половина таблицы: точнее 2-я формула Ньютона";
    }
    break;
  case Method::NewtonBackward:
    r.center = n - 1;
    r.t = (X - nodes[n - 1].x) / h;
    r.value = newtonBackward(d, nodes, h, X, r.order);
    if (r.t < -mid) {
      r.note = "левая половина таблицы: точнее 1-я формула Ньютона";
    }
    break;
  case Method::GaussI:
    r.center = nearestIndex(nodes, X);
    r.value = gaussForward(d, nodes, h, X, r.center, r.t, r.order);
    if (r.order < 2) {
      r.note = edge;
    } else if (r.t < -kEps) {
      r.note = "при t < 0 точнее 2-я формула Гаусса";
    }
    break;
  case Method::GaussII:
    r.center = nearestIndex(nodes, X);
    r.value = gaussBackward(d, nodes, h, X, r.center, r.t, r.order);
    if (r.order < 2) {
      r.note = edge;
    } else if (r.t > kEps) {
      r.note = "при t > 0 точнее 1-я формула Гаусса";
    }
    break;
  case Method::Stirling:
    r.center = nearestIndex(nodes, X);
    r.value = stirling(d, nodes, h, X, r.center, r.t, r.order);
    if (r.order < 2) {
      r.note = edge;
    } else if (n % 2 == 0) {
      r.note = "рекомендуется нечётное число узлов";
    } else if (std::abs(r.t) > 0.25) {
      r.note = "рекомендуется |t| ≤ 0,25";
    }
    break;
  case Method::Bessel: {
    int c = static_cast<int>(std::floor((X - nodes[0].x) / h));
    if (c < 0) {
      c = 0;
    }
    if (c > n - 2) {
      c = n - 2;
    }
    r.center = c;
    r.value = bessel(d, nodes, h, X, c, r.t, r.order);
    if (r.order < 1) {
      r.note = edge;
    } else if (n % 2 == 1) {
      r.note = "рекомендуется чётное число узлов";
    } else if (std::abs(r.t - 0.5) > 0.25) {
      r.note = "рекомендуется 0,25 ≤ t ≤ 0,75";
    }
    break;
  }
  case Method::Lagrange:
    break;
  }

  if (r.note.empty()) {
    r.note = rangeNote(nodes, X);
  }
  return r;
}

const char *methodKey(Method m) {
  switch (m) {
  case Method::Lagrange:
    return "lagrange";
  case Method::NewtonForward:
    return "newton_fwd";
  case Method::NewtonBackward:
    return "newton_bwd";
  case Method::GaussI:
    return "gauss1";
  case Method::GaussII:
    return "gauss2";
  case Method::Stirling:
    return "stirling";
  case Method::Bessel:
    return "bessel";
  }
  return "";
}

const char *methodTitle(Method m) {
  switch (m) {
  case Method::Lagrange:
    return "Многочлен Лагранжа";
  case Method::NewtonForward:
    return "Ньютон (вперёд)";
  case Method::NewtonBackward:
    return "Ньютон (назад)";
  case Method::GaussI:
    return "Гаусс (1-я формула)";
  case Method::GaussII:
    return "Гаусс (2-я формула)";
  case Method::Stirling:
    return "Стирлинг";
  case Method::Bessel:
    return "Бессель";
  }
  return "";
}

} // namespace interp
