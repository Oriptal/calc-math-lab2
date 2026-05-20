#ifndef BACKEND_H
#define BACKEND_H

#include "GaussModule.hpp"
#include "IntegrationModule.hpp"
#include "RootModule.hpp"
#include "SystemModule.hpp"

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class Backend : public QObject {
  Q_OBJECT

public:
  explicit Backend(QObject *parent = nullptr) : QObject(parent) {}

  Q_INVOKABLE QVariantMap processData(qint32 method, qint32 equation,
                                      const QVariantMap &map) const {
    return RootModule::processData(method, equation, map);
  }

  Q_INVOKABLE QVariantList sampleCurve(qint32 equation, qreal left, qreal right,
                                       qint32 points) const {
    return RootModule::sampleCurve(equation, left, right, points);
  }

  Q_INVOKABLE QVariantMap processSystemData(const QVariantMap &map) const {
    return SystemModule::processSystemData(map);
  }

  Q_INVOKABLE QVariantMap
  processSystemDataByEquation(qint32 equation, const QVariantMap &map) const {
    return SystemModule::processSystemDataByEquation(equation, map);
  }

  Q_INVOKABLE QVariantMap sampleSystemCurves(qreal left, qreal right,
                                             qreal bottom, qreal top,
                                             qint32 points) const {
    return SystemModule::sampleSystemCurves(left, right, bottom, top, points);
  }

  Q_INVOKABLE QVariantMap sampleSystemCurvesByEquation(qint32 equation,
                                                       qreal left, qreal right,
                                                       qreal bottom, qreal top,
                                                       qint32 points) const {
    return SystemModule::sampleSystemCurvesByEquation(equation, left, right,
                                                      bottom, top, points);
  }

  Q_INVOKABLE QVariantMap integrate(qint32 functionId,
                                    const QVariantMap &map) const {
    return IntegrationModule::integrate(functionId, map);
  }

  Q_INVOKABLE QVariantList sampleIntegrand(qint32 functionId, qreal left,
                                           qreal right, qint32 points) const {
    return IntegrationModule::sampleIntegrand(functionId, left, right, points);
  }

  Q_INVOKABLE QVariantList integrandDiscontinuities(qint32 functionId) const {
    return IntegrationModule::integrandDiscontinuities(functionId);
  }

  Q_INVOKABLE QVariantMap solveLinearSystem(const QVariantMap &payload) const {
    return GaussModule::solve(payload);
  }

  Q_INVOKABLE QVariantMap generateLinearSystem(qint32 size) const {
    return GaussModule::generate(size);
  }
};

#endif
