cmake_minimum_required(VERSION 3.16)

project(HelloWorldQuickProject VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appHelloWorldQuickProject
    main.cpp
    Backend.hpp
)

set_source_files_properties(Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appHelloWorldQuickProject
    URI HelloWorldQuickProject
    QML_FILES
        Main.qml
        Theme.qml
        components/Body.qml
        components/EquationCard.qml
        components/Header.qml
        components/ModuleRoot.qml
        components/ModuleSettings.qml
        components/ModuleSystem.qml
        components/MyButton.qml
        components/MyRect.qml
        components/MyText.qml
        components/NavButton.qml
    RESOURCES
        assets/equation0.svg
        assets/equation1.svg
        assets/equation2.svg
        assets/equation3.svg
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appHelloWorldQuickProject PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appHelloWorldQuickProject
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appHelloWorldQuickProject
    PRIVATE
        Qt6::Quick
        calc_core
)

include(GNUInstallDirs)
install(TARGETS appHelloWorldQuickProject
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

add_library(calc_core calc/Solvers.hpp calc/solver.cpp)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
