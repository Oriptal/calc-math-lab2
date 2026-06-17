#include "backend/Backend.hpp"
#include <QApplication>
#include <QFont>
#include <QFontDatabase>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <qqml.h>

int main(int argc, char *argv[]) {
  QApplication app(argc, argv);
  app.setWindowIcon(QIcon(":/qt/qml/CompMath/assets/icon-256.png"));

  QFontDatabase::addApplicationFont(
      ":/qt/qml/CompMath/assets/fonts/JetBrainsMonoNerdFont-Regular.ttf");
  QFontDatabase::addApplicationFont(
      ":/qt/qml/CompMath/assets/fonts/JetBrainsMonoNerdFont-Bold.ttf");
  QApplication::setFont(QFont("JetBrainsMono Nerd Font"));

  qmlRegisterType<Backend>("Calc", 1, 0, "Backend");
  QQmlApplicationEngine engine;
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("CompMath", "Main");

  return app.exec();
}
