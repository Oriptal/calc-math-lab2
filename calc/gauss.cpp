#include "Gauss.hpp"

#include <algorithm>
#include <cmath>
#include <random>
#include <utility>

GaussResult
GaussSolver::solve(const std::vector<std::vector<double>> &inputMatrix,
                   const std::vector<double> &inputAugmentation) const {
  GaussResult result;

  const int n = static_cast<int>(inputMatrix.size());
  if (n <= 0 || n > kMaxSize ||
      static_cast<int>(inputAugmentation.size()) != n) {
    result.status = GAUSS_INVALID_SIZE;
    return result;
  }
  for (const auto &row : inputMatrix) {
    if (static_cast<int>(row.size()) != n) {
      result.status = GAUSS_INVALID_SIZE;
      return result;
    }
  }

  std::vector<std::vector<double>> matrix(inputMatrix);
  std::vector<double> augmentation(inputAugmentation);
  std::vector<double> solution(n, 0.0);
  std::vector<double> residuals(n, 0.0);

  int swapSign = 1;
  double det = 1.0;

  for (int i = 0; i < n; ++i) {
    std::pair<double, int> maxValue = {matrix[i][i], i};
    for (int j = i + 1; j < n; ++j) {
      if (std::abs(maxValue.first) < std::abs(matrix[j][i])) {
        maxValue.first = matrix[j][i];
        maxValue.second = j;
      }
    }

    if (std::abs(maxValue.first) < kEps) {
      det = 0.0;
      continue;
    }

    if (maxValue.second != i) {
      std::swap(matrix[i], matrix[maxValue.second]);
      std::swap(augmentation[i], augmentation[maxValue.second]);
      swapSign = -swapSign;
    }

    for (int j = i + 1; j < n; ++j) {
      const double c = -matrix[j][i] / matrix[i][i];
      for (int k = i; k < n; ++k) {
        matrix[j][k] += c * matrix[i][k];
      }
      augmentation[j] += c * augmentation[i];
    }
  }

  for (int i = 0; i < n; ++i) {
    det *= matrix[i][i];
  }
  det *= swapSign;

  result.triangular = matrix;
  result.reducedAugmentation = augmentation;
  result.determinant = det;

  if (std::abs(det) < kEps) {
    for (int i = 0; i < n; ++i) {
      bool allZeros = true;
      for (int j = 0; j < n; ++j) {
        if (std::abs(matrix[i][j]) > kEps) {
          allZeros = false;
          break;
        }
      }
      if (allZeros && std::abs(augmentation[i]) > kEps) {
        result.status = GAUSS_NO_SOLUTIONS;
        return result;
      }
    }
    result.status = GAUSS_INFINITE_SOLUTIONS;
    return result;
  }

  for (int i = n - 1; i >= 0; --i) {
    double sum = 0.0;
    for (int j = i + 1; j < n; ++j) {
      sum += matrix[i][j] * solution[j];
    }
    solution[i] = (augmentation[i] - sum) / matrix[i][i];
  }

  for (int i = 0; i < n; ++i) {
    double sum = 0.0;
    for (int j = 0; j < n; ++j) {
      sum += solution[j] * inputMatrix[i][j];
    }
    residuals[i] = sum - inputAugmentation[i];
  }

  result.status = GAUSS_SINGLE_SOLUTION;
  result.solution = solution;
  result.residuals = residuals;
  return result;
}

std::vector<std::vector<double>>
GaussSolver::generateMatrix(int n, unsigned long long seed) {
  std::mt19937_64 gen(seed);
  std::uniform_real_distribution<double> urd(0.0, 10.0);
  std::vector<std::vector<double>> res(n, std::vector<double>(n));
  for (int i = 0; i < n; ++i) {
    for (int j = 0; j < n; ++j) {
      res[i][j] = urd(gen);
    }
  }
  return res;
}

std::vector<double> GaussSolver::generateAugmentation(int n,
                                                      unsigned long long seed) {
  std::mt19937_64 gen(seed ^ 0x9E3779B97F4A7C15ULL);
  std::uniform_real_distribution<double> urd(0.0, 10.0);
  std::vector<double> res(n);
  for (int i = 0; i < n; ++i) {
    res[i] = urd(gen);
  }
  return res;
}
