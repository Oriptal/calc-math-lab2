#include "backend/Backend.hpp"
#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <qqml.h>

int main(int argc, char *argv[]) {
  QApplication app(argc, argv);
  app.setWindowIcon(
      QIcon(":/qt/qml/CompMath/assets/icon-256.png"));

  qmlRegisterType<Backend>("Calc", 1, 0, "Backend");
  QQmlApplicationEngine engine;
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("CompMath", "Main");

  return app.exec();
}
