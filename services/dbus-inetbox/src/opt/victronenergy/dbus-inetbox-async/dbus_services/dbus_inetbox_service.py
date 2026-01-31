#!/usr/bin/env python3

from dbus_base_service import dbus_base_service
from dbus_constants import dbus_constants

class dbusInetboxService(dbus_base_service):

 
	def __init__(self, name: str, port:str, classAndVrmInstance:str, onValueChanged):

		self._registerCore(
			port,
			classAndVrmInstance,
			paths =  {	
				'/CustomName': {'initial': name,'writable': True},
				'/Values/WaterMode': {'initial': None,'writable': True},
				'/Values/WaterCurrentTemp': {'initial': None,'writable': False},
				'/Values/WaterTargetTemp': {'initial': None,'writable': True},
    		'/Values/HeatingMode': {'initial': None,'writable': True},
				'/Values/HeatingTargetTemp': {'initial': None,'writable': True},
				'/Values/HeatingCurrentTemp': {'initial': None,'writable': False},
				'/Values/ElectricityPowerLevel': {'initial': None,'writable': True},
				'/Values/EnergyMix': {'initial': None,'writable': True},
				'/Values/AirConMode': {'initial': None,'writable': True},
				'/Values/AirConTargetTemp': {'initial': None,'writable': True},
				'/Values/AirConFanSpeed': {'initial': None,'writable': True},
				'/Values/Status': {'initial': None,'writable': False},
				'/Values/Error': {'initial': None,'writable': False},
				'/Values/Clock': {'initial': None,'writable': False},
				'/Values/Alive': {'initial': None,'writable': False},
				
			},
			onValueChanged = onValueChanged
			)
	
 
 
		