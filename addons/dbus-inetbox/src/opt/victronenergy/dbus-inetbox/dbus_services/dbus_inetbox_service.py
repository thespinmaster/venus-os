#!/usr/bin/env python3

from dbus_base_service import dbus_base_service
import os
from dbus_constants import dbus_constants

class dbusInetboxService(dbus_base_service):
 
	def __init__(self, portName:str, classAndVrmInstance:str, serviceIdentifier:str = "", onValueChangedCallback = None):
		 
		connection = os.path.basename(portName) # convert from /dev/ttyxxx to ttyxxx

		classAndVrmInstanceParts = classAndVrmInstance.split(':')
		className = classAndVrmInstanceParts[0]
		deviceInstance = int(classAndVrmInstanceParts[1])
 
		serviceName = "com.victronenergy.{}.{}".format(
			className, dbus_constants.DBUS_PRODUCT_NAME + "_" + serviceIdentifier)
		
		self._registerCore(
			connection,
			deviceInstance,
			serviceName,
			dbus_constants.PRODUCT_ID,
			dbus_constants.PRODUCT_NAME,
			dbus_constants.FIRMWARE_VERSION,
			dbus_constants.HARDWARE_VERSION,
			paths =  {	
				'/CustomName': {'initial': "",'writable': True},
				'/Temperature': {'initial': None,'writable': False},
				'/CustomDevicePage': {'initial': dbus_constants.CUSTOM_DEVICE_PAGE,'writable': False},
				'/Port': {'initial': portName,'writable': False},
				'/CustomAlarm': {'initial': 0,'writable': True},
				'/CustomAlarmText': {'initial': "",'writable': True},
				'/Values/WaterCurrentTemp': {'initial': None,'writable': False},
				'/Values/WaterTargetTemp': {'initial': None,'writable': True},
    		'/Values/HeatingMode': {'initial': None,'writable': True},
				'/Values/HeatingTargetTemp': {'initial': None,'writable': True},
				'/Values/CurrentRoomTemp': {'initial': None,'writable': False},
				'/Values/ElectricityPowerLevel': {'initial': None,'writable': True},
				'/Values/EnergyMix': {'initial': None,'writable': True},
				'/Values/EnergyMixCombined': {'initial': None,'writable': True},
				'/Values/AirconMode': {'initial': None,'writable': True},
				'/Values/AirconTargetTemp': {'initial': None,'writable': True},
				'/Values/AirconFanSpeed': {'initial': None,'writable': True},
				'/Values/Status': {'initial': None,'writable': False},
				'/Values/Error': {'initial': None,'writable': False},
				'/Values/ErrorDescription': {'initial': None,'writable': False},
				'/Values/Clock': {'initial': None,'writable': False},
				'/Values/Alive': {'initial': None,'writable': False},
				'/SwitchableOutput/heating/ShowUIControl': {'initial': 0,'writable': False},
				'/SwitchableOutput/heating/Settings/Type': {'initial': 3,'writable': False},
				'/SwitchableOutput/heating/Settings/Unit': {'initial': '/Temperature','writable': False},
				'/SwitchableOutput/heating/Settings/DimmingMin': {'initial': 5,'writable': False},
				'/SwitchableOutput/heating/Settings/DimmingMax': {'initial': 30,'writable': False},
				'/SwitchableOutput/heating/Settings/StepSize': {'initial': 1,'writable': False},
				'/SwitchableOutput/heating/Settings/Decimals': {'initial': 1,'writable': False},
				'/SwitchableOutput/heating/Dimming': {'initial': None,'writable': True},
				'/SwitchableOutput/heating/Measurement': {'initial': None,'writable': False},
				'/SwitchableOutput/aircon/Dimming': {'initial': None,'writable': True},
				'/SwitchableOutput/aircon/ShowUIControl': {'initial': 0,'writable': False},
				'/SwitchableOutput/aircon/Settings/Type': {'initial': 3,'writable': False},
				'/SwitchableOutput/aircon/Settings/Unit': {'initial': '/Temperature','writable': False},
				'/SwitchableOutput/aircon/Settings/DimmingMin': {'initial': 16,'writable': False},
				'/SwitchableOutput/aircon/Settings/DimmingMax': {'initial': 31,'writable': False},
				'/SwitchableOutput/aircon/Settings/StepSize': {'initial': 1,'writable': False},
				'/SwitchableOutput/aircon/Settings/Decimals': {'initial': 1,'writable': False},
				'/SwitchableOutput/aircon/Measurement': {'initial': None,'writable': False},
			
			},
			onValueChanged = onValueChangedCallback
			)
	
 
 
		