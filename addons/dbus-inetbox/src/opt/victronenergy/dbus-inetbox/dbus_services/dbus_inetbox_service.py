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
				'/Values/WaterCurrentTemp': {'initial': None,'writable': False},
				'/Values/WaterTargetTemp': {'initial': 0,'writable': True},
    		'/Values/HeatingMode': {'initial': None,'writable': True},
				'/Values/HeatingTargetTemp': {'initial': None,'writable': True},
				'/Values/HeatingCurrentTemp': {'initial': None,'writable': False},
				'/Values/ElectricityPowerLevel': {'initial': None,'writable': True},
				'/Values/EnergyMix': {'initial': None,'writable': True},
				'/Values/EnergyMixCombined': {'initial': None,'writable': True},
				'/Values/AirconMode': {'initial': None,'writable': True},
				'/Values/AirconTargetTemp': {'initial': None,'writable': True},
				'/Values/AirconFanSpeed': {'initial': None,'writable': True},
				'/Values/Status': {'initial': None,'writable': False},
				'/Values/Error': {'initial': None,'writable': False},
				'/Values/Clock': {'initial': None,'writable': False},
				'/Values/Alive': {'initial': None,'writable': False}
			},
			onValueChanged = onValueChangedCallback
			)
	
 
 
		