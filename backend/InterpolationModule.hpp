#pragma once

#include <QString>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

class InterpolationModule {
public:
  static QVariantMap interpolate(const QVariantMap &payload);

  static QVariantList sampleInterpolationMethod(const QString &methodKey,
                                                const QVariantList &points,
                                                double xMin, double xMax,
                                                qint32 samples);

  static QVariantList functionList();

  static QVariantList sampleFunction(qint32 funcId, double a, double b,
                                     qint32 points);

  static QVariantMap loadFile(const QUrl &url);
};
