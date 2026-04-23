#pragma once

#include <QString>

inline double parseDouble(QString value, bool *ok) {
  value.replace(',', '.');
  return value.toDouble(ok);
}
