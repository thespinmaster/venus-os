cmake_minimum_required(VERSION 3.12)

project(OpkgHelpersQmlPlugin LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

set(QMLPLUGIN_QT_MAJOR "auto" CACHE STRING "Qt major version to use: 5, 6, or auto")

if(QMLPLUGIN_QT_MAJOR STREQUAL "6")
	find_package(Qt6 REQUIRED COMPONENTS Core Qml)
	set(QT_LIBS Qt6::Core Qt6::Qml)
elseif(QMLPLUGIN_QT_MAJOR STREQUAL "5")
	find_package(Qt5 REQUIRED COMPONENTS Core Qml)
	set(QT_LIBS Qt5::Core Qt5::Qml)
else()
	find_package(Qt6 QUIET COMPONENTS Core Qml)
	if(Qt6_FOUND)
		set(QT_LIBS Qt6::Core Qt6::Qml)
	else()
		find_package(Qt5 REQUIRED COMPONENTS Core Qml)
		set(QT_LIBS Qt5::Core Qt5::Qml)
	endif()
endif()

add_library(opkghelpersplugin MODULE
	OpkgHelpersPlugin.cpp
	ProcessRunner.cpp
	FileHelper.cpp
	FileHelper.h
)

target_include_directories(opkghelpersplugin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(opkghelpersplugin PRIVATE ${QT_LIBS})

target_compile_features(opkghelpersplugin PRIVATE cxx_std_11)

set_target_properties(opkghelpersplugin PROPERTIES
	LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../data/opkg-helpers/qml/OpkgHelpers"
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../data/opkg-helpers/qml/OpkgHelpers"
)

add_custom_command(
	TARGET opkghelpersplugin POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E copy
		"${CMAKE_CURRENT_SOURCE_DIR}/qmldir"
		"${CMAKE_CURRENT_SOURCE_DIR}/../data/opkg-helpers/qml/OpkgHelpers/qmldir"
)
