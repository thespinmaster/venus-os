
# controls the interaction between the 
# inetboxapp, the dbus_inetbox_service and the settings

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

class InetboxController:
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
	_sid : str
	_app : InetboxApp
	_lin : Lin
	_settings : SettingsDevice
	_dbusInetboxService : dbusInetboxService

	def __init__(self, tasks: TaskManager, serialPort, sid, debug_lin, debug_inet, record_file=None):
		
		self.log.setLevel(logging.DEBUG)
		self._serialPort = serialPort
		self._sid = sid

		self._initializeSettings() # sets/gets class_and_vrm_instance
		
		self._app = InetboxApp(tasks, debug_inet)  
		self._lin = Lin(self._app, serialPort, tasks, debug_lin, record_file)

		self._app.add_publish_callback(self.inetbox_value_to_dbus)
		
		classAndVrmInstance = self._settings['class_and_vrm_instance']
		serviceIdentifier = "sid_" + sid
  
		self._dbusInetboxService = dbusInetboxService(
																	serialPort,
																	classAndVrmInstance, 
																	serviceIdentifier , 
																	self.dbus_value_to_inetbox)
  
		self._dbusInetboxService.set_value("/Theme", self._settings["/Theme"])
	
	# serial port -> dbus
	def inetbox_value_to_dbus(self, name: str, value):

		try:

			self.log.debug(f'inetbox_value_to_dbus:, {name}={value}: type={type(value)}')
			
			dbusName = self.map_or_debug(self.LIN_TO_DBUS_MAPPING, name)
			if dbusName == "": 
				return

			if (name == "target_temp_room"): # coerse using LastHeatingTemp
				if (value == "0"):
					value = self._settings["/LastHeatingTemp"]

			self._dbusInetboxService.set_value(self.DBUS_PATH + dbusName, value)

			if (name == "current_temp_room"):
				temperature_value = self._to_float(value) # MUST be a float
				if temperature_value is not None:
					self._dbusInetboxService.set_value("/Temperature", temperature_value)
			elif (name == "el_power_level" or name == "energy_mix"):
				self._toEnergyMixCombined(dbusName, value)

		except Exception as e:
			self.log.error(f"Exception in: inetbox_value_to_dbus: name={name}, value={value}: {e}")

	# dbus -> serial port
	def dbus_value_to_inetbox(self, path : str, value ):
		
		self.log.debug(f'dbus_value_to_inetbox:, {path}={value}')

		try:
			if not path.startswith(self.DBUS_PATH):
				if (path == "/CustomName" or path == "/Theme"):
					self._settings[path] = value
					return True
				return False
	
			name = path.removeprefix(self.DBUS_PATH)
		
			if (name == "EnergyMixCombined"):
				self._fromEnergyMixCombined(value)
				return True

			linName = self.map_or_debug(self.DBUS_TO_LIN_MAPPING, name)
			if linName == "":
				return False

			self._app.set_status(linName, value)

			self._dbusInetboxService.set_value(path, value)
	
			if (name == "HeatingTargetTemp"):
				if (self._dbusInetboxService.get_value("/Values/HeatingMode") == "off"):
					self._settings["/LastHeatingTemp"] = value

			elif (name == "HeatingMode"):
				if (value == "off"):
					self._settings["/LastHeatingTemp"] = self._dbusInetboxService.get_value("/Values/HeatingTargetTemp")
					self.dbus_value_to_inetbox("/Values/HeatingTargetTemp", 0)
				else:
					heating_temp = self._to_float(self._dbusInetboxService.get_value("/Values/HeatingTargetTemp"))
					if (heating_temp < 5):
						heating_temp = self._settings["/LastHeatingTemp"]
						heating_temp = 5 if heating_temp < 5 else heating_temp

					self.dbus_value_to_inetbox("/Values/HeatingTargetTemp", heating_temp)

			return True
		except Exception as e:
			self.log.error(f"Exception in: dbus_value_to_inetbox: path={path}, value={value}: {e}")
			return False
		
	############################################
	# Occurs when the a dbus setting value changes
	############################################
	def _handle_dbus_setting_changed(self, path, oldvalue, newvalue):
		try:
			self.log.info('setting changed, setting: %s, old: %s, new: %s' % (path, oldvalue, newvalue))
			if (path == "/CustomName" or path == "/Theme"):
				self._dbusInetboxService.set_value(path, newvalue)
				return True
			
			return False
		except Exception as e:
			self.log.error(f"Exception in: _handle_dbus_setting_changed: path={path}, value={newvalue}: {e}")
			return False

	def _fromEnergyMixCombined(self, value: str):
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

	def _toEnergyMixCombined(self, dbusname : str, value: str):
		energyMix = ""
		elpower = ""
		energyMixCombined=""

		if (dbusname == "EnergyMix"):
			if (value != "gas"):
				elpower = self._dbusInetboxService.get_value(self.DBUS_PATH + "ElectricityPowerLevel")
			energyMix = value
   
		elif (dbusname == "ElectricityPowerLevel"):
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

	def _to_float(self, value):
		try:
			return float(value)
		except (TypeError, ValueError):
			self.log.warning("Skipping non-numeric temperature value: %r", value)
			return 0
    
	############################################
	# Initializes the dbus device settings
	# Needs custom UI
	############################################ 
	def _initializeSettings(self):

		logging.debug("Initializing settings")
		
		# unique path used to generate unique ClassAndVrmInstance value 
		# see https://github.com/victronenergy/localsettings#using-addsetting-to-allocate-a-vrm-device-instance
		self._settingsPath = f'/Settings/Devices/{dbus_constants.DBUS_PRODUCT_NAME}_sid_{self._sid}'
  
		self._settings = SettingsDevice(
			bus = dbusconnection(),
			#name, path, value, min (0), max (0)
			supportedSettings = {
				'class_and_vrm_instance' : [f'{self._settingsPath}/ClassAndVrmInstance', 
						f"{dbus_constants.SERVICE_TYPE_TEMPERATURE}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
						
				'/Sid' : [f'{self._settingsPath}/Sid', self._sid, 0, 0],
				'/CustomName' : [f'{self._settingsPath}/CustomName', "", 0, 1],
				'/LastHeatingTemp' : [f'{self._settingsPath}/LastHeatingTemp', 16, 4, 30],
				#'syncClock' : [f'{settingsPath}/SyncClock', 1, 0, 1],
				},
			eventCallback = self._handle_dbus_setting_changed)

	def map_or_debug(self, mapping, name):
		if name in mapping:
			return mapping[name]
		else:
			#logging.debug(f"map_or_debug:unknown value {name}")
			print(f"[LIN-DEBUG] map_or_debug:unknown value {name}")
			return ""
