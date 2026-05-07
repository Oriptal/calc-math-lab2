#pragma once

#include "calc/Integrators.hpp"

#include <QString>
#include <QVariantList>
#include <QVariantMap>

#include <vector>

class IntegrationModule {
public:
  static QVariantMap integrate(qint32 functionId, const QVariantMap &map);
  static QVariantList sampleIntegrand(qint32 functionId, qreal left,
                                      qreal right, qint32 points);
  static QVariantList integrandDiscontinuities(qint32 functionId);

private:
  static bool selectIntegrand(qint32 functionId, IntegrandFunc &f,
                              std::vector<double> &discontinuities);
  static bool isIntegrandDefined(qint32 functionId, double a, double b);
};
