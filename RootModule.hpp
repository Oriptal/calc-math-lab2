#pragma once

#include "calc/Solvers.hpp"

#include <QString>
#include <QVariantList>
#include <QVariantMap>

class RootModule {
public:
  static QVariantMap processData(qint32 method, qint32 equation,
                                 const QVariantMap &map);
  static QVariantList sampleCurve(qint32 equation, qreal left, qreal right,
                                  qint32 points);

private:
  static bool selectEquation(qint32 equation, MathFunc &f);
};
