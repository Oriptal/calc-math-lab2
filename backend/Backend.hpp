#ifndef BACKEND_H
#define BACKEND_H

#include "ApproximationModule.hpp"
#include "GaussModule.hpp"
#include "IntegrationModule.hpp"
#include "InterpolationModule.hpp"
#include "RootModule.hpp"
#include "SystemModule.hpp"

#include <QObject>
#include <QUrl>
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

  Q_INVOKABLE QVariantMap approximate(const QVariantMap &payload) const {
    return ApproximationModule::approximate(payload);
  }

  Q_INVOKABLE QVariantList sampleApproximation(const QString &kind,
                                               const QVariantList &coeffs,
                                               qreal xMin, qreal xMax,
                                               qint32 points) const {
    return ApproximationModule::sampleApproximation(kind, coeffs, xMin, xMax,
                                                    points);
  }

  Q_INVOKABLE QVariantMap interpolate(const QVariantMap &payload) const {
    return InterpolationModule::interpolate(payload);
  }

  Q_INVOKABLE QVariantList sampleInterpolationMethod(const QString &methodKey,
                                                     const QVariantList &points,
                                                     qreal xMin, qreal xMax,
                                                     qint32 samples) const {
    return InterpolationModule::sampleInterpolationMethod(methodKey, points,
                                                          xMin, xMax, samples);
  }

  Q_INVOKABLE QVariantList interpolationFunctions() const {
    return InterpolationModule::functionList();
  }

  Q_INVOKABLE QVariantList sampleInterpolationFunction(qint32 funcId, qreal a,
                                                       qreal b,
                                                       qint32 points) const {
    return InterpolationModule::sampleFunction(funcId, a, b, points);
  }

  Q_INVOKABLE QVariantMap loadInterpolationFile(const QUrl &url) const {
    return InterpolationModule::loadFile(url);
  }
};

#endif
