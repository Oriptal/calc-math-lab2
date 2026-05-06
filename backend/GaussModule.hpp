#pragma once

#include <QString>
#include <QVariantList>
#include <QVariantMap>

class GaussModule {
public:
  static QVariantMap solve(const QVariantMap &payload);
  static QVariantMap generate(qint32 size);
};
