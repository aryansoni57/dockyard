cmake_minimum_required(VERSION 3.20)
project(dockyard-kcmhost LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.7 REQUIRED COMPONENTS Core Gui Qml Quick Widgets)
find_package(KF6KCMUtils REQUIRED)
find_package(KF6CoreAddons REQUIRED)
find_package(KF6Config REQUIRED)
find_package(KF6ColorScheme REQUIRED)
find_package(KF6WindowSystem REQUIRED)
qt_standard_project_setup(REQUIRES 6.7)
qt_add_qml_module(kcmhost
    URI dev.dockyard.kcmhost
    VERSION 1.0
    PLUGIN_TARGET kcmhostplugin
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/dev/dockyard/kcmhost
    SOURCES kcmmodel.cpp kcmmodel.h kcmhost.cpp kcmhost.h
)
target_link_libraries(kcmhost PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Widgets
    KF6::KCMUtils KF6::KCMUtilsQuick KF6::KCMUtilsCore KF6::CoreAddons KF6::ConfigCore KF6::ColorScheme KF6::WindowSystem)
target_link_libraries(kcmhostplugin PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Widgets
    KF6::KCMUtils KF6::KCMUtilsQuick KF6::KCMUtilsCore KF6::CoreAddons KF6::ConfigCore KF6::ColorScheme KF6::WindowSystem)
