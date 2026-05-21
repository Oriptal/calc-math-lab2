#pragma once

#include <QString>
#include <QVariantList>
#include <QVariantMap>

class ApproximationModule {
public:
  static QVariantMap approximate(const QVariantMap &payload);
  static QVariantList sampleApproximation(const QString &kindStr,
                                          const QVariantList &coeffs,
                                          double xMin, double xMax,
                                          qint32 points);
};
