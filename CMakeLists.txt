cmake_minimum_required(VERSION 3.16)

if(POLICY CMP0207)
    cmake_policy(SET CMP0207 NEW)
endif()

project(HelloWorldQuickProject VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_DEPLOY_USE_PATCHELF ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Charts Widgets Concurrent)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appHelloWorldQuickProject
    main.cpp
    Backend.hpp
    BackendUtil.hpp
    RootModule.hpp
    RootModule.cpp
    SystemModule.hpp
    SystemModule.cpp
    IntegrationModule.hpp
    IntegrationModule.cpp
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
        components/ModuleIntegration.qml
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
        assets/system0.svg
        assets/system1.svg
        assets/system2.svg
        assets/integrand0.svg
        assets/integrand1.svg
        assets/integrand2.svg
        assets/integrand3.svg
        assets/integrand4.svg
        assets/icon-256.png
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
        Qt6::Charts
        Qt6::Widgets
        Qt6::Concurrent
        calc_core
)

include(GNUInstallDirs)
install(TARGETS appHelloWorldQuickProject
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

set(deploy_script_args
    TARGET appHelloWorldQuickProject
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    NO_TRANSLATIONS
)

if(UNIX AND NOT APPLE)
    # Plugin filtering arguments are not accepted by Qt 6.8's deploy API.
    # Keep the broader filtering only for newer Qt versions, while CI on 6.8
    # still uses the standard deploy path.
    if(Qt6_VERSION VERSION_GREATER_EQUAL "6.9.0")
        list(APPEND deploy_script_args
            EXCLUDE_PLUGIN_TYPES
                egldeviceintegrations
                generic
                imageformats
                networkinformation
                platforminputcontexts
                platformthemes
                qmltooling
                styles
                wayland-decoration-client
                wayland-graphics-integration-client
                wayland-shell-integration
            INCLUDE_PLUGINS qxcb;qsvg;qsvgicon
            EXCLUDE_PLUGINS qeglfs;qlinuxfb;qminimal;qminimalegl;qoffscreen;qvkkhrdisplay;qvnc;qwayland
        )
    endif()
endif()

qt_generate_deploy_qml_app_script(
    ${deploy_script_args}
)

install(SCRIPT ${deploy_script})

add_library(calc_core
    calc/Solvers.hpp
    calc/solver.cpp
    calc/Integrators.hpp
    calc/integrators.cpp
)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
