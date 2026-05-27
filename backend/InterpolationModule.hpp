#pragma once

#include <QString>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

class InterpolationModule {
public:
  // Полный расчёт: таблица конечных разностей + все методы в точке X.
  static QVariantMap interpolate(const QVariantMap &payload);

  // Точки интерполяционного многочлена (Лагранж) для построения графика.
  static QVariantList sampleInterpolation(const QVariantList &points,
                                          double xMin, double xMax,
                                          qint32 samples);

  // Список встроенных функций для режима «Функция».
  static QVariantList functionList();

  // Табулирование встроенной функции на [a, b] в указанном числе точек.
  static QVariantList sampleFunction(qint32 funcId, double a, double b,
                                     qint32 points);

  // Список встроенных тестовых наборов данных.
  static QVariantList datasetList();

  // Загрузка встроенного набора по идентификатору (из ресурсного файла).
  static QVariantMap loadDataset(qint32 id);

  // Загрузка произвольного файла данных, выбранного пользователем.
  static QVariantMap loadFile(const QUrl &url);
};
