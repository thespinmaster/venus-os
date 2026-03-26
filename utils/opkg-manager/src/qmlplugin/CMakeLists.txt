cmake_minimum_required(VERSION 3.12)

project(OpkgManagerQmlPlugin LANGUAGES CXX)

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


# Use qt_add_qml_module for Qt 6 QML plugin with bytecode
qt_add_qml_module(OpkgManagerplugin
	URI OpkgManager
	VERSION 1.0
	
	#[[
	QML_FILES
		resources/test.qml
		resources/OpkgEditBoxLargeText.qml
		resources/OpkgHeaderDescriptionItem.qml
		resources/OpkgObjectCustomOverviewPages.qml
		resources/OpkgPageSettingsCustomMenus.qml
		resources/OpkgPageSettingsSubMenu.qml
		resources/PageSettingsOpkg.qml
		resources/PageSettingsOpkgFeeds.qml
		resources/PageSettingsOpkgPackageInstall.qml
		resources/PageSettingsOpkgPackages.qml

		#../opt/victronenergy/gui/qml/OpkgEditBoxLargeText.qml
		#../opt/victronenergy/gui/qml/OpkgHeaderDescriptionItem.qml
		#../opt/victronenergy/gui/qml/OpkgObjectCustomOverviewPages.qml
		#../opt/victronenergy/gui/qml/OpkgPageSettingsCustomMenus.qml
		#../opt/victronenergy/gui/qml/OpkgPageSettingsSubMenu.qml
		#../opt/victronenergy/gui/qml/PageSettingsOpkg.qml
		#../opt/victronenergy/gui/qml/PageSettingsOpkgFeeds.qml
		#../opt/victronenergy/gui/qml/PageSettingsOpkgPackageInstall.qml
		#../opt/victronenergy/gui/qml/PageSettingsOpkgPackages.qml
	RESOURCE_PREFIX /
	]]
	
	SOURCES
		OpkgManagerPlugin.cpp
		ProcessRunner.cpp
		FileHelper.cpp
		FileHelper.h
)

target_include_directories(OpkgManagerplugin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OpkgManagerplugin PRIVATE ${QT_LIBS})

target_compile_features(OpkgManagerplugin PRIVATE cxx_std_11)


set_target_properties(OpkgManagerplugin PROPERTIES
	LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../opt/victronenergy/gui/qml/OpkgManager"
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../opt/victronenergy/gui/qml/OpkgManager"
)

add_custom_command(
	TARGET OpkgManagerplugin POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E copy
		"${CMAKE_CURRENT_SOURCE_DIR}/qmldir"
		"${CMAKE_CURRENT_SOURCE_DIR}/../opt/victronenergy/gui/qml/OpkgManager/qmldir"
)
