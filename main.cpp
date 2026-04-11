#include "Backend.hpp"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <qqml.h>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  qmlRegisterType<Backend>("Calc", 1, 0, "Backend");
  QQmlApplicationEngine engine;
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("HelloWorldQuickProject", "Main");

  return app.exec();
}
