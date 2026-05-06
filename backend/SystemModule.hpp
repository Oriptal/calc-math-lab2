#pragma once

#include "../calc/Solvers.hpp"

#include <QPointF>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

#include <functional>

class SystemModule {
public:
  static QVariantMap processSystemData(const QVariantMap &map);
  static QVariantMap processSystemDataByEquation(qint32 equation,
                                                 const QVariantMap &map);
  static QVariantMap sampleSystemCurves(qreal left, qreal right, qreal bottom,
                                        qreal top, qint32 points);
  static QVariantMap sampleSystemCurvesByEquation(qint32 equation, qreal left,
                                                  qreal right, qreal bottom,
                                                  qreal top, qint32 points);

private:
  struct SystemFunctions {
    std::function<double(double, double)> first;
    std::function<double(double, double)> second;
  };

  static bool selectSystemIterFunctions(qint32 equation, SystemFunc &phiX,
                                        SystemFunc &phiY);
  static SystemFunctions systemFunctions(qint32 equation);
  static QVector<QPointF>
  traceZeroCurve(const std::function<double(double, double)> &F, double left,
                 double right, double bottom, double top, int samples);
  static QVariantList toVariantList(const QVector<QPointF> &points);
};
