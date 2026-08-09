import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Controls.impl as CP
import Victron.VenusOS
import Victron.Gauges

Page {
	id: root

	required property bool animationEnabled
  property var device: pageLoader.device

	property int buttonOffsetX: 30
	property int buttonOffsetY: 10
	property real xOffset: 1.2

	property real backgroundOffsetY: 20
	property real inetboxOffsetY: 100

	property string image_boat_glow: "qrc:/images/boat_glow.png"
	//property string image_boat_glow: ""

	GaugeModel { id: gaugeModel } // aka storage tanks

	RowLayout {
		id: mainRow
		spacing: 20

		anchors {
			left: parent.left;leftMargin: 20
			right: parent.right
		}
		TankLevelsColumnLayout {
			model: gaugeModel
			Layout.fillWidth: true
		}
		InputLoadsColumnLayout {}
		BatteryInfoColumnLayout {}
		OutputLoadsColumnLayout {}
	}

  RoomTempsColumnLayout {
		id: mainTemps
		anchors {top: mainRow.bottom; left: parent.left;leftMargin: 40; topMargin:10 }
	}

	MinimalSlider {
		id: targetTemperatureSlider

		visible: inetbox.heatingOn || inetbox.airconOn
		anchors {
			left: parent.left; leftMargin: 5
			top: parent.top; topMargin: root.inetboxOffsetY + 198
		}
		value: inetbox.targetTemperature
		//onValueChanged: inetbox.updateTargetTemperatureValue(value)
		onPressedChanged: {
			if (!pressed)
				inetbox.updateTargetTemperatureValue(value)
		}
		from: inetbox.heatingOn ? 5 : 16
		to: inetbox.heatingOn ? 30 : 31
		stepSize: 1
		width: 225
		rotation: 250.5
	}

	CycleButtonGroup { id: cycleButtonGroup}

	// Water
	CycleButton {
		id: waterHeaterCycleButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/image_freshwater.svg"
		//% "Water"
		text: qsTrId("inetbox_option_energy_water")
		binding: inetbox.waterTargetTemperatureItem
		anchors {
			left: parent.left; leftMargin: 150
			top: mainRow.bottom; topMargin: inetboxOffsetY
		}

		model: [{
				value: "0",
				//% "Off"
				valueText: qsTrId("inetbox_option_off"),
				color: "grey"
			}, {
				value: "40.0",
				//% "Eco"
				valueText:  qsTrId("inetbox_option_eco"),
				color: "white"
			}, {
				value: "60.0",
				//% "Hot"
				valueText: qsTrId("inetbox_option_hot"),
				color: "white"
			}, {
				value: "200.0",
				//% "Boost"
				valueText: qsTrId("inetbox_option_boost"),
				color: "white"
			}]

	}
	QuantityLabel {
		//id: waterHeaterCurrentTemperature
		font.pixelSize: 24
		unit: Global.systemSettings.temperatureUnit
		value: inetbox.waterCurrentTemperatureItem.value
		anchors {left: waterHeaterCycleButton.right; verticalCenter: waterHeaterCycleButton.verticalCenter}

	}
	// Heating
	CycleButton {
		id: heatingCycleButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/image_heating.svg"
		binding: inetbox.heatingModeItem

		//% "Heating"
		text: qsTrId("inetbox_option_energy_heating")
		anchors {
			left: waterHeaterCycleButton.left; leftMargin: root.buttonOffsetX
			top: waterHeaterCycleButton.bottom; topMargin: root.buttonOffsetY
		}
		model: [{
				value: "off",
				//% "Off"
				valueText: qsTrId("inetbox_option_off"),
				color: "grey"
			}, {
				value: "eco",
				//% "Eco"
				valueText: qsTrId("inetbox_option_eco"),
				color: "white"
			}, {
				value: "high",
				//% "High"
				valueText: qsTrId("inetbox_option_high"),
				color: "white"
			}]
	}
	// Aircon mode
	CycleButton {
		id: airconModeCycleButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/image_aircon.svg"
		binding: inetbox.airconModeItem
		//% "Aircon"
		text: qsTrId("inetbox_option_energy_aircon")
		anchors {
			left: heatingCycleButton.left; leftMargin: root.buttonOffsetX
			top: heatingCycleButton.bottom; topMargin: root.buttonOffsetY
		}
		model: [{
				value: "off",
				//% "Off"
				valueText: qsTrId("inetbox_option_off"),
				color: "grey"
			}, {
				value: "cool",
				//% "Cool"
				valueText: qsTrId("inetbox_option_cool"),
				color: "white"
			}, {
				value: "vent",
				//% "Vent"
				valueText:  qsTrId("inetbox_option_vent"),
				color: "white"
			}, {
				value: "hot",
				//% "Hot"
				valueText: qsTrId("inetbox_option_hot"),
				color: "white"
			}, {
				value: "auto",
				//% "Auto"
				valueText: qsTrId("inetbox_option_auto"),
				color: "white"
			}]
	}
	// Aircon Fan Speed
	CycleButton {
		id: airconFanSpeedCycleButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/image_fan.svg"
		icon.color: airconModeCycleButton.icon.color
		binding: inetbox.airconFanSpeedItem
		//% "Fan speed"
		text: qsTrId("inetbox_option_energy_fan_speed")

		anchors {
			left: airconModeCycleButton.right
			top: airconModeCycleButton.top
		}
		model: [{
				value: "low",
				//% "Low"
				valueText: qsTrId("inetbox_option_low"),
				color: "white"
			}, {
				value: "mid",
				//% "Mid"
				valueText: qsTrId("inetbox_option_mid"),
				color: "white"
			}, {
				value: "high",
				//% "High"
				valueText: qsTrId("inetbox_option_high"),
				color: "white"
			}, {
				value: "night",
				//% "Night"
				valueText: qsTrId("inetbox_option_night"),
				color: "white"
			}, {
				value: "auto",
				//% "Auto"
				valueText: qsTrId("inetbox_option_auto"),
				color: "lightseagreen"
			}]
	}
	// EnergyMix
	CycleButton {
		id: energyMixButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/image_energy_mix.svg"
		binding: inetbox.energyMixItem
		//% "Energy Mix"
		text: qsTrId("inetbox_option_energy_mix")

		anchors {
			left: airconModeCycleButton.left
			leftMargin: root.buttonOffsetX //* root.xOffset
			top: airconModeCycleButton.bottom
			topMargin: root.buttonOffsetY
		}
		model: [{
				value: "gas",
				//% "Gas"
				valueText: qsTrId("inetbox_option_gas"),
				color: '#ffab03'
			}, {
				value: "mix1",
				//% "Mix1"
				valueText: qsTrId("inetbox_option_mix1"),
				color: "green"
			}, {
				value: "mix2",
				//% "Mix2"
				valueText: qsTrId("inetbox_option_mix2"),
				color: "green"
			}, {
				value: "el1",
				//% "El1"
				valueText: qsTrId("inetbox_option_el1"),
				color: "lightskyblue"
			}, {
				//% "El2"
				valueText: qsTrId("inetbox_option_el2"),
				color: "lightskyblue"
			}]
	}

	// version
	Label {
		color: "grey"
		anchors {right: parent.right; rightMargin: 50; bottom: bg_image.bottom}
		text: pageLoader.plugin_version
	}

  // left image
	CP.ColorImage {
		id: bg_image
		height: 380
		mirror: true
		rotation: 180
		source: image_boat_glow
		width: 800
		z: -1
		anchors {
			left: parent.left; leftMargin: 20
			top: mainRow.bottom; topMargin: -20
		}
	}

	//right image
	CP.ColorImage {
		id: bg_image2
		height: 380
		mirror: true
		//rotation: 180
		source: image_boat_glow
		width: 800
		z: -1
		anchors {
			right: parent.right; leftMargin: 20
			top: mainRow.bottom; topMargin: 50
		}
	}

////////////////////////////////////////////////

	Component.onCompleted: {
		console.log("OpkgCustomPageModel: onCompleted:",
		"page=", "MotorhomePage_Landscape.qml",
		"version=", pageLoader.plugin_version,
		"bg_image2.source=", bg_image2.source)
	}

	Component.onDestruction: {
		console.log("OpkgCustomPageModel: onDestruction:",
		"page=", "MotorhomePage_Landscape.qml",
		"version=", pageLoader.plugin_version)
	}

////////////////////////////////////////////
// Data
////////////////////////////////////////////

QtObject {
	id: inetbox

	property bool heatingOn: heatingModeItem.valid && heatingModeItem.value != "off"
	property bool airconOn: airconModeItem.valid && airconModeItem.value != "off"
	readonly property real targetTemperature: heatingOn ? heatingTargetTempItem.value : airconTargetTemperatureItem.value

	onHeatingOnChanged: exclusiveHeating(airconModeItem)
	onAirconOnChanged: exclusiveHeating(heatingModeItem)

	property VeQuickItemTemperature currentTemperatureItem: VeQuickItemTemperature {uid: inetbox.deviceUid("CurrentRoomTemp")}
	property VeQuickItemTemperature waterCurrentTemperatureItem: VeQuickItemTemperature {uid: inetbox.deviceUid("WaterCurrentTemp")}
	property VeQuickItem waterTargetTemperatureItem: VeQuickItem { uid: inetbox.deviceUid("WaterTargetTemp")}
	property VeQuickItem heatingModeItem: VeQuickItem { uid: inetbox.deviceUid("HeatingMode")}
	property VeQuickItemTemperature heatingTargetTempItem: VeQuickItemTemperature {uid: inetbox.deviceUid("HeatingTargetTemp")}

	property VeQuickItem airconModeItem: VeQuickItem {uid: inetbox.deviceUid("AirconMode")}
	property VeQuickItemTemperature airconTargetTemperatureItem: VeQuickItemTemperature { uid: inetbox.deviceUid("AirconTargetTemp")}
	property VeQuickItem airconFanSpeedItem: VeQuickItem {uid: inetbox.deviceUid("AirconFanSpeed")}
	property VeQuickItem energyMixItem: VeQuickItem {uid: inetbox.deviceUid("EnergyMixCombined")}

	function deviceUid(value) {
		return root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/" + value) : ""
	}

	function exclusiveHeating(itemToTurnOff) {
		console.log("MH:exclusiveHeating:", itemToTurnOff)
		if (heatingOn === true && airconOn === true)
			itemToTurnOff.setValue("off")
	}
	function updateTargetTemperatureValue(value) {
		if (heatingOn) {
			heatingTargetTempItem.setValue(value)
		} else if (airconOn) {
			inetbox.airconTargetTemperatureItem.setValue(value)
		}
	}

}

	////////////////////////////////////////////
	// Components
	////////////////////////////////////////////
	component VeQuickItemTemperature: VeQuickItem {
			sourceUnit: Units.unitToVeUnit(VenusOS.Units_Temperature_Celsius)
			displayUnit: Units.unitToVeUnit(Global.systemSettings.temperatureUnit)
	}

	component RoomTempsColumnLayout: ColumnLayout {

		QuantityLabel {
			id: tempValue
			font.pixelSize: 44
			unit: Global.systemSettings.temperatureUnit

			value: inetbox.currentTemperatureItem.value
		}

		QuantityLabel {
			font.pixelSize: 24
			value: targetTemperatureSlider.pressed ? targetTemperatureSlider.value : inetbox.targetTemperature
			visible: inetbox.heatingOn | inetbox.airconOn
			unit: Global.systemSettings.temperatureUnit
			unitColor: Theme.color_overviewPage_widget_battery_font_secondary
		}
	}

	component TankLevelsColumnLayout: ColumnLayout {
		id: tanks
		spacing: 1

		property alias model: repeater.model
		property real levelThickness: 6
		property real maxLabelWidth: 0

		Repeater {
			id: repeater

			Loader {
				id: tankLoader
				// 1. Only instantiate the component if it's not a battery
				active: model.tankType !== VenusOS.Tank_Type_Battery
				visible: active

				Layout.fillHeight: true
    		Layout.fillWidth: true

			 	sourceComponent: Row {
					id: row
					width: tankLoader.width
					height: tankLoader.height
					spacing: 6

					property int gaugeStatus: Theme.getValueStatus(model.level, model.valueType)
					property color valueColor: Theme.statusColorValue(row.gaugeStatus)
					property color levelColor: Theme.statusColorValue(row.gaugeStatus, true)

					// 1. [name] Right-aligned, sized dynamically to the longest string
					Label {
						id: valueLabel
						text: model.name

						horizontalAlignment: Text.AlignRight
						anchors.verticalCenter: parent.verticalCenter

						property int unit
						property quantityInfo quantity

						states: State {
							when: Global.systemSettings.briefView.unit.value !== VenusOS.BriefView_Unit_None
							PropertyChanges {
								target: valueLabel

								text: model.name + " "  + quantity.number + quantity.unit
								quantity: Units.getDisplayText(unit, value)
								//width: updateMaxLabelWidth()
								unit: Global.systemSettings.briefView.unit.value === VenusOS.BriefView_Unit_Percentage
										? VenusOS.Units_Percentage
										: Global.systemSettings.volumeUnit

							}

						}

						onImplicitWidthChanged: {
							if (implicitWidth > tanks.maxLabelWidth)
								tanks.maxLabelWidth = implicitWidth;
						}
						width: tanks.maxLabelWidth
					}

					// 2. [Icon]
					CP.IconImage {
						id: img
						source: model.icon
						width: Theme.geometry_widgetHeader_icon_size
						fillMode: Image.Pad
						anchors.verticalCenter: parent.verticalCenter
					}

					// Background fill
					Rectangle {
						id: levelBack
						anchors.verticalCenter: parent.verticalCenter
						width: Math.max(50, row.width - valueLabel.width - img.width - row.spacing)
						height: levelThickness
						color: row.levelColor
						radius: height / 2
						Rectangle {

							anchors.left: parent.left
							height: parent.height
							width: levelBack.width * model.level / 100
							color: row.valueColor
							radius: height / 2
						}
					}
				}
			}
		}
	}

	component InputLoadsColumnLayout: ColumnLayout {
		id: dcInputLoads
		spacing: 1

		MotorhomeGaugeQuantityRow {
			id: solarYield
			visible: Global.solarInputs.inputCount > 0
			alignment: Qt.AlignLeft | Qt.AlignTop
			icon.source: "qrc:/images/solaryield.svg"
			quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Any
			quantityLabel.dataObject: Global.system.solar
		}

		MotorhomeGaugeQuantityRow {
			id: dcInGaugeQuantity
			visible: Global.dcInputs.model.count > 0
			alignment: Qt.AlignLeft | Qt.AlignBottom
			icon.source: Global.dcInputs.model.count === 1 ? VenusOS.dcMeter_iconForType(Global.dcInputs.model.firstMeterType) : VenusOS.dcMeter_iconForMultipleTypes()
			quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Dc
			quantityLabel.dataObject: Global.dcInputs
		}

		MotorhomeGaugeQuantityRow {
			id: acInGaugeQuantity
			visible: Global.acInputs.findValidSource() !== VenusOS.AcInputs_InputSource_NotAvailable
			//visible: true
			alignment: Qt.AlignLeft | Qt.AlignVCenter
			icon.source: Global.acInputs.sourceIcon(Global.acInputs.highlightedInput?.source ?? Global.acInputs.findValidSource())
			quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_AcInputOnly
			quantityLabel.dataObject: Global.acInputs.highlightedInput
		}
	}

	component BatteryInfoColumnLayout: ColumnLayout {
			MotorhomeBattery {
				id: batteryWidget
				animationEnabled: root.animationEnabled
				size: VenusOS.OverviewWidget_Size_XS
				topPadding: 0
				//Layout.fillWidth: true
				Layout.fillHeight: true
			}

	}

	component OutputLoadsColumnLayout: ColumnLayout {
		id: outputLoads
		spacing: 1

		MotorhomeGaugeQuantityRow {
			id: acLoadGauge
			visible: Global.system.hasAcLoads
			alignment: Qt.AlignRight | Qt.AlignVCenter
			icon.source: "qrc:/images/acloads.svg"
			quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Ac
			quantityLabel.dataObject: Global.system.load.ac
		}

		MotorhomeGaugeQuantityRow {
			id: dcLoadGauge
			visible: Global.system.dc.hasPower
			alignment: Qt.AlignRight | Qt.AlignVCenter
			icon.source: "qrc:/images/dcloads.svg"
			quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Dc
			quantityLabel.dataObject: Global.system.dc
		}
	}

	component MinimalSlider: T.Slider {
		id: control

		//property color trackColor: "#E0E0E0"
		property color progressColor: "#2196F3"
		property color handleColor: '#911e88e5'
		property color handlePressedColor: "#1565C0"
		property color tickColor: '#ffffff'

		property bool hideProgress: true
		property bool hideTicks: true

		property real tickThickness: 2
		property real tickLength: tickThickness
		property real tickRadius: tickLength / 2
		property real tickAngle: 0

		property real handleDiameter: 24
		property real trackThickness: 2

		// Default sizing
		implicitWidth: Math.max(implicitBackgroundWidth + leftPadding + rightPadding, implicitHandleWidth + leftPadding + rightPadding)
		implicitHeight: Math.max(implicitBackgroundHeight + topPadding + bottomPadding, implicitHandleHeight + topPadding + bottomPadding)

		// Reserve horizontal padding so the circle handle doesn't clip at min/max edges
		padding: 0
		leftPadding: handleDiameter / 2
		rightPadding: handleDiameter / 2

		// Apply rotation slant around center
		transformOrigin: Item.Center

		// --- Track / Background ---
		background: Item {
			x: control.leftPadding
			y: control.topPadding + control.availableHeight / 2 - height / 2
			implicitWidth: 200 // default width
			implicitHeight: control.trackThickness
			width: control.availableWidth
			height: implicitHeight

			// Active Progress Fill
			Rectangle {
				width: control.visualPosition * parent.width
				height: parent.height
				color: control.progressColor

				opacity: control.hideProgress ? (control.pressed ? 1.0 : 0.0) : 1.0
				Behavior on opacity  {
					enabled: control.hideProgress
					NumberAnimation {
						duration: control.pressed ? 2000 : 150
						// Optional: Easing curves make the transition feel even smoother
						easing.type: control.pressed ? Easing.OutCubic : Easing.InQuad
					}
				}
			}

			// Tick Marks (Visible when slider is pressed)
			Item {
				anchors.fill: parent

				opacity: control.hideTicks ? (control.pressed ? 1.0 : 0.0) : 1.0
				Behavior on opacity  {
					enabled: control.hideTicks
					NumberAnimation {
						duration: control.pressed ? 2000 : 150
						// Optional: Easing curves make the transition feel even smoother
						easing.type: control.pressed ? Easing.OutCubic : Easing.InQuad
					}
				}

				Repeater {
					model: (control.stepSize > 0 && control.to > control.from) ? Math.floor((control.to - control.from) / control.stepSize) + 1 : 0

					delegate: Rectangle {
						id: tick
						rotation: control.tickAngle
						transformOrigin: Item.Center
						required property int index
						property real range: control.to - control.from
						property real fraction: range > 0 ? (index * control.stepSize) / range : 0

						x: fraction * parent.width - (width / 2)
						anchors.verticalCenter: parent.verticalCenter
						width: control.tickThickness
						height: control.tickLength
						color: control.tickColor
						radius: control.tickThickness
					}
				}
			}
		}

		// --- Circular Handle Delegate ---
		handle: Rectangle {
			x: control.leftPadding + control.visualPosition * control.availableWidth - width / 2
			y: control.topPadding + control.availableHeight / 2 - height / 2
			implicitWidth: control.handleDiameter
			implicitHeight: control.handleDiameter
			radius: width / 2
			color: control.pressed ? control.handlePressedColor : control.handleColor

			border.color: "#FFFFFF"
			border.width: 2
		}
	}

	component CycleButtonGroup : QtObject {
		property real _maxTextWidth: 0
		property real valueWidth: 100
		property real secondaryWidth: 40
	}

	component CycleButton: Item {
		id: control

    required property VeQuickItem binding
    property int currentIndex
    readonly property var currentValue: binding?.value
		property alias icon: button.icon
		property var model: []

		property alias text: button.text
		property alias valueText: valueLabel.text

		property alias valueColor: valueLabel.color
		property real fontPixelSize: 24

		property CycleButtonGroup group

		implicitHeight: button.height
		implicitWidth: valueLabel.x + valueLabel.width
		icon.color: control.model[control.currentIndex].color

		onCurrentIndexChanged: {
			if (binding && currentIndex >= -1 && currentIndex <= model.length)
				 	binding.setValue(model[currentIndex].value)
		}
		onCurrentValueChanged: {
			for (var i = 0; i < model.length; i++) {
				if (model[i].value == currentValue) {
					currentIndex = i
					return
				}
			}
		}

		Button {
			id: button
			flat: true
			font.pixelSize: control.fontPixelSize
			onClicked: {
				control.currentIndex = (control.currentIndex === control.model.length - 1)
				? 0
				: control.currentIndex + 1;
			}

			anchors {
				left: parent.left
				verticalCenter: parent.verticalCenter
			}
			onImplicitWidthChanged: {
				if (control.group === undefined) return
				if (implicitWidth > control.group._maxTextWidth)
					control.group._maxTextWidth = implicitWidth;
			}
		}
		Label {
			id: valueLabel
			text: control.model[control.currentIndex].valueText ?? ""
			font.pixelSize: control.fontPixelSize
			color: "dimgrey"
			width: control.group === undefined ? undefined: control.group.valueWidth
			anchors {
				left: control.group == undefined ? button.right : button.left
				leftMargin: control.group == undefined ? 0 : control.group._maxTextWidth + 10
				verticalCenter: button.verticalCenter
			}
		}
	}

}
