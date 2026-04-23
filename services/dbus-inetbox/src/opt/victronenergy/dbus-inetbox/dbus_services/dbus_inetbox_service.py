#!/usr/bin/env python3

from dbus_base_service import dbus_base_service
 
class dbusInetboxService(dbus_base_service):
 
	def __init__(self, name: str, portName:str, serviceIdentifier:str,  classAndVrmInstance:str, onValueChangedCallback):

		self._registerCore(
			portName,
			serviceIdentifier,
			classAndVrmInstance,
			paths =  {	
				'/CustomName': {'initial': name,'writable': True},
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
				'/Values/Alive': {'initial': None,'writable': False},
				'/Temperature': {'initial': None,'writable': False}
				
			},
			onValueChanged = onValueChangedCallback
			)
	
 
 
		