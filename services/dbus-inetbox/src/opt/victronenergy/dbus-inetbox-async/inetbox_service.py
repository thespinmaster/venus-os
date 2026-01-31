

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
		"AirConMode": "aircon_operating_mode",
		"AirConTargetTemp": "target_temp_aircon",
		"AirConFanSpeed": "aircon_vent_mode",
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
		"aircon_operating_mode": "AirConMode",
		"target_temp_aircon": "AirConTargetTemp",
		"aircon_vent_mode": "AirConFanSpeed",
		"operating_status": "Status",
		"error_code": "Error",
		"clock": "Clock",
		"alive": "Alive"
		}  
	
	log = logging.getLogger(__name__)
	_serialPort : str
	_app : InetboxApp
	_lin : Lin
	_settings : SettingsDevice
	_dbusInetboxService : dbusInetboxService

	def __init__(self, tasks: TaskManager, serialPort, debug_lin, debug_inet, record_file=None):
		self.log.setLevel(logging.DEBUG)
		self._serialPort=serialPort
		
		#self._initializeSettings()
		
		self._app = InetboxApp(tasks, debug_inet)  
		self._lin = Lin(self._app, serialPort, tasks, debug_lin, record_file)

		self._app.add_publish_callback(self.published_inetbox_value)
		
		#classAndVrmInstance = self._settings['inetbox_class_and_vrm_instance']
 
		#self._dbusInetboxService = dbusInetboxService("InetBox", serialPort, classAndVrmInstance, self._onInetboxValueChanged)
	
	def published_inetbox_value(self, name: str, value: str):
		logging.info(f'setting changed, {name}={value}')
		dbusPath=self.map_or_debug(self.LIN_TO_DBUS_MAPPING, name)
		if dbusPath == "": 
			return
		#self._dbusInetboxService.set_value(self.DBUS_PATH + dbusPath, value)

	def _onInetboxValueChanged(self, path : str, value : str):
		if not path.startswith(self.DBUS_PATH):
			return
		name=path.removeprefix(self.DBUS_PATH)
		linPath=self.map_or_debug(self.DBUS_TO_LIN_MAPPING, name)
		if linPath == "": 
			return
		self._app.set_status(linPath, value)
 
		#self._dbusInetboxService.set_value(name, value)
 
	############################################
	# Occurs when the a device setting value changes
	############################################
	def _handle_changed_setting(self, setting, oldvalue, newvalue):
		logging.debug('setting changed, setting: %s, old: %s, new: %s' % (setting, oldvalue, newvalue))
		dbusPath=self.map_or_debug(self.DBUS_TO_LIN_MAPPING,setting)
		#self._start_stop_services(setting, newvalue)
		return True
	
	############################################
	# Initializes the dbus device settings
	# Needs custom UI
	############################################ 
	def _initializeSettings(self):

		logging.debug("Initializing settings")
		
		# unique path used to generate unique ClassAndVrmInstance value 
		# see https://github.com/victronenergy/localsettings#using-addsetting-to-allocate-a-vrm-device-instance
		portName = os.path.basename(self._serialPort)

		settingsPath = f'/Settings/Devices/{dbus_constants.SAFE_PRODUCT_NAME}_{portName}'
		
		self._settings = SettingsDevice(
			bus = dbusconnection(),
			supportedSettings = {
				'inetbox_class_and_vrm_instance' : [f'{settingsPath}_inetbox/ClassAndVrmInstance', 
													f"{dbus_constants.SAFE_PRODUCT_NAME}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
				},
			eventCallback = self._handle_changed_setting)

	def map_or_debug(self, mapping, value):
		if value in mapping:
			return mapping[value]
		else:
			logging.debug(f"map_or_debug:unknown value {value}")
			return ""
