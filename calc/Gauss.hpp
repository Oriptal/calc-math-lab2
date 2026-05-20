#pragma once

#include <vector>

enum GaussStatus {
  GAUSS_SINGLE_SOLUTION = 0,
  GAUSS_NO_SOLUTIONS = 1,
  GAUSS_INFINITE_SOLUTIONS = 2,
  GAUSS_INVALID_SIZE = 3
};

struct GaussResult {
  GaussStatus status = GAUSS_SINGLE_SOLUTION;
  std::vector<std::vector<double>> triangular;
  std::vector<double> reducedAugmentation;
  std::vector<double> solution;
  std::vector<double> residuals;
  double determinant = 0.0;
};

class GaussSolver {
public:
  static constexpr double kEps = 1e-12;
  static constexpr int kMaxSize = 20;

  GaussResult solve(const std::vector<std::vector<double>> &matrix,
                    const std::vector<double> &augmentation) const;

  static std::vector<std::vector<double>>
  generateMatrix(int n, unsigned long long seed);

  static std::vector<double> generateAugmentation(int n,
                                                  unsigned long long seed);
};
