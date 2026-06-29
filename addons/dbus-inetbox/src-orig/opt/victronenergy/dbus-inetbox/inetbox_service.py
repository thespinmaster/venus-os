

import logging
import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), 'ext'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'dbus_services'))

from dbus_services.dbus_constants import dbus_constants
from dbus_services.dbus_connection import dbusconnection
from ext.settingsdevice import SettingsDevice  # available in the velib_python repository
from lin import Lin
from inetboxapp import InetboxApp
from taskmanager import TaskManager


from dbus_services.dbus_inetbox_service import dbusInetboxService

class InetboxService:
	DBUS_PATH="/Values/"

	DBUS_TO_LIN_MAPPING = {
		"WaterCurrentTemp": "current_temp_water",
		"WaterTargetTemp": "target_temp_water",
		"HeatingMode": "heating_mode",
		"HeatingTargetTemp": "target_temp_room",
		"HeatingCurrentTemp": "current_temp_room",
		"ElectricityPowerLevel": "el_power_level",
		"EnergyMix": "energy_mix",
		"AirconMode": "aircon_operating_mode",
		"AirconTargetTemp": "target_temp_aircon",
		"AirconFanSpeed": "aircon_vent_mode",
		"Status": "operating_status",
		"Error": "error_code",
		"Clock": "clock",
		"Alive": "alive"
	}

	LIN_TO_DBUS_MAPPING = {
		"current_temp_water": "WaterCurrentTemp",
		"target_temp_water": "WaterTargetTemp",
		"heating_mode": "HeatingMode",
		"target_temp_room": "HeatingTargetTemp",
		"current_temp_room": "HeatingCurrentTemp",
		"el_power_level": "ElectricityPowerLevel",
		"energy_mix": "EnergyMix",
		"aircon_operating_mode": "AirconMode",
		"target_temp_aircon": "AirconTargetTemp",
		"aircon_vent_mode": "AirconFanSpeed",
		"operating_status": "Status",
		"error_code": "Error",
		"clock": "Clock",
		"alive": "Alive"
		}

	log = logging.getLogger(__name__)
	_serialPort : str
	_sid: str
	_app : InetboxApp
	_lin : Lin
	_settings : SettingsDevice
	_dbusInetboxService : dbusInetboxService

	def __init__(self, tasks: TaskManager, serialPort: str, sid:str, debug_lin, debug_inet, record_file=None):
		self.log.setLevel(logging.DEBUG)
		self._serialPort = serialPort
		self._sid = sid

		self._initializeSettings()

		self._app = InetboxApp(tasks, debug_inet)
		self._lin = Lin(self._app, serialPort, tasks, debug_lin, record_file)

		self._app.add_publish_callback(self.published_inetbox_value)

		classAndVrmInstance = self._settings['class_and_vrm_instance']

		serviceIdentifier = "sid_" + self._sid

		self._dbusInetboxService = dbusInetboxService("Inetbox", serialPort, serviceIdentifier, classAndVrmInstance, self._onInetboxValueChanged)

  # from device to UI
	def published_inetbox_value(self, name: str, value: str):
		logging.info(f'setting changed, {name}={value}')
		dbusName = self.map_or_debug(self.LIN_TO_DBUS_MAPPING, name)
		if dbusName == "":
			return

		self._dbusInetboxService.set_value(self.DBUS_PATH + dbusName, value)

		self._toEnergyMixCombined(dbusName, value)

  # from UI to device
	def _onInetboxValueChanged(self, path : str, value : str):
		if not path.startswith(self.DBUS_PATH):
			return 1
		name = path.removeprefix(self.DBUS_PATH)

		if (name == "EnergyMixCombined"):
			self._fromEnergyMixCombined(value)
			return 0

		linName = self.map_or_debug(self.DBUS_TO_LIN_MAPPING, name)
		if linName == "":
			return 1

		self._app.set_status(linName, value)

		self._dbusInetboxService.set_value(path, value)
		return 0

	############################################
	# Occurs when the a device setting value changes
	############################################
	def _handle_changed_setting(self, setting, oldvalue, newvalue):
		logging.debug('setting changed, setting: %s, old: %s, new: %s' % (setting, oldvalue, newvalue))
		#dbusPath=self.map_or_debug(self.DBUS_TO_LIN_MAPPING,setting)
		#self._start_stop_services(setting, newvalue)


		return True

	def _fromEnergyMixCombined(self, value):
		energyMixCombined = value
		mix = ""
		elpower = ""

		if (energyMixCombined == "Gas"):
			mix = "gas"
		elif (energyMixCombined == "EL1"):
			elpower = "900"
			mix = "electricity"
		elif (energyMixCombined == "EL2"):
			elpower = "1800"
			mix = "electricity"
		elif (energyMixCombined == "Mix1"):
			elpower = "900"
			mix = "mix"
		elif (energyMixCombined == "Mix2"):
			elpower = "1800"
			mix = "mix"
		else:
			return

		self._app.set_status("energy_mix", mix)
		self._dbusInetboxService.set_value(self.DBUS_PATH + "EnergyMix", mix)

		self._app.set_status("el_power_level", elpower)
		self._dbusInetboxService.set_value(self.DBUS_PATH + "ElectricityPowerLevel", elpower)

	def _toEnergyMixCombined(self,name,value):
		energyMix = ""
		elpower = ""
		energyMixCombined=""
		if (name == "EnergyMix"):
			if (value != "gas"):
				elpower = self._dbusInetboxService.get_value(self.DBUS_PATH + "ElectricityPowerLevel")

		elif (name == "ElectricityPowerLevel"):
			energyMix = self._dbusInetboxService.get_value(self.DBUS_PATH + "EnergyMix")
			elpower = value

		if (energyMix == "gas"):
			energyMixCombined = "Gas"
		elif (energyMix == "mix"):
			if elpower == "900":
				energyMixCombined = "Mix1"
			elif elpower == "1800":
				energyMixCombined = "Mix2"
		elif (energyMix == "electricity"):
			if elpower == "900":
				energyMixCombined = "EL1"
			elif elpower == "1800":
				energyMixCombined = "EL2"

		if (energyMixCombined):
			self._dbusInetboxService.set_value(self.DBUS_PATH + "EnergyMixCombined", energyMixCombined)

	############################################
	# Initializes the dbus device settings
	# Needs custom UI
	############################################
	def _initializeSettings(self):

		logging.debug("Initializing settings")

    # class_and_vrm_instance
		# unique path used to generate unique ClassAndVrmInstance value
		# see https://github.com/victronenergy/localsettings#using-addsetting-to-allocate-a-vrm-device-instance

		settingsPath = f'/Settings/CustomDevices/{dbus_constants.SAFE_PRODUCT_NAME}_{self._sid}'

		self._settings = SettingsDevice(
			bus = dbusconnection(),
			#name, path, value, min (0), max (0)
			supportedSettings = {
				'class_and_vrm_instance' : [f'{settingsPath}/ClassAndVrmInstance',
						f"{dbus_constants.SERVICE_TYPE_TEMPERATURE}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
				'theme' : [f'{settingsPath}/Theme',"light", 0, 0],
				'showAircon' : [f'{settingsPath}/ShowAircon', 1, 0, 1],
				'enabled' : [f'{settingsPath}/Enabled', 1, 0, 1]
				#'syncClock' : [f'{settingsPath}/SyncClock', 1, 0, 1],
				},
			eventCallback = self._handle_changed_setting)


	def map_or_debug(self, mapping, name):
		if name in mapping:
			return mapping[name]
		else:
			#logging.debug(f"map_or_debug:unknown value {value}")
			print(f"map_or_debug:unknown value {name}")
			return ""
