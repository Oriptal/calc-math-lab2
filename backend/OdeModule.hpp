#pragma once

#include <QString>
#include <QVariantList>
#include <QVariantMap>

class OdeModule {
public:
  static QVariantMap solve(const QVariantMap &payload);

  static QVariantList equationList();

  static QVariantList sampleExact(qint32 equationId, double x0, double y0,
                                  double a, double b, qint32 points);
};
