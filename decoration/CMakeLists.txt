cmake_minimum_required(VERSION 3.20)
project(dockyard-glass VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

add_compile_options(-Wall -Wextra -Wpedantic)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui)
find_package(KDecoration3 REQUIRED)
find_package(KF6CoreAddons REQUIRED)
find_package(KF6Config REQUIRED)

option(BUILD_PREVIEW "Build the offscreen preview/test harness" ON)

# Shared drawing code: used by the plugin and by the offscreen preview harness.
add_library(dockyardglass_style STATIC
    src/glassstyle.cpp
    src/glassstyle.h
)
target_link_libraries(dockyardglass_style PUBLIC Qt6::Gui KDecoration3::KDecoration KF6::ConfigCore)
target_include_directories(dockyardglass_style PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)

# The KDecoration3 plugin itself. KWin looks it up by KPlugin Id in the
# Qt plugin folder "org.kde.kdecoration3".
add_library(org.dockyard.glass MODULE
    src/plugin.cpp
    src/decoration.cpp
    src/decoration.h
    src/button.cpp
    src/button.h
)
set_target_properties(org.dockyard.glass PROPERTIES PREFIX "")
set_property(SOURCE src/plugin.cpp APPEND PROPERTY OBJECT_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/dockyardglass.json)
target_link_libraries(org.dockyard.glass PRIVATE
    dockyardglass_style
    Qt6::Core Qt6::Gui
    KDecoration3::KDecoration
    KF6::CoreAddons
    KF6::ConfigCore
)
# Build the plugin into build/plugins/org.kde.kdecoration3/ so the harness can
# find it with QT_PLUGIN_PATH=build/plugins exactly like KWin does.
set_target_properties(org.dockyard.glass PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/${KDECORATION_PLUGIN_DIR})

set(DOCKYARD_PLUGIN_INSTALL_ROOT "lib/qt6/plugins" CACHE STRING "Qt plugin root, relative to CMAKE_INSTALL_PREFIX")
install(TARGETS org.dockyard.glass DESTINATION ${DOCKYARD_PLUGIN_INSTALL_ROOT}/${KDECORATION_PLUGIN_DIR})

if(BUILD_PREVIEW)
    add_executable(glass-harness tests/harness.cpp)
    target_link_libraries(glass-harness PRIVATE
        dockyardglass_style
        Qt6::Core Qt6::Gui
        KDecoration3::KDecoration
        KDecoration3::KDecoration3Private
        KF6::CoreAddons
    )
    add_dependencies(glass-harness org.dockyard.glass)
endif()
