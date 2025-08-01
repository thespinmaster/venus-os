#!/usr/bin/env python3

from dbus_base_service import dbus_base_service
from dbus_constants import dbus_constants

class battery_service(dbus_base_service):

    MinVoltage = 11.63
    MaxVoltage = 12.89
 
    def __init__(self, name, port, classAndVrmInstance, capacity, onValueChanged):

        self._registerCore(
            port,
            classAndVrmInstance,
            paths =  {
                '/Voltage': {'initial': None,'writable': False},
                '/CustomName': {'initial': name,'writable': True},
                '/Soc': {'initial': None,'writable': True},
                '/Capacity': {'initial': capacity,'writable': True},
                '/MinVoltage': {'initial': MinVoltage,'writable': True},
                '/MaxVoltage': {'initial': MaxVoltage,'writable': True}
                },
            onValueChanged = onValueChanged
            )
    

    @staticmethod
    def calcBatterySoc(self, value):
        if (value == None | value <= 0):
            return 0
        #V_MAX = 12.89 # 100% charged
        V_MIN = 11.63 # 0% dead
        V_RANGE = 1.26 # (V_MAX - V_MIN)
        #soc = (float(value) - V_MIN) / (V_MAX - V_MIN)
 
        soc = ((float(value) - V_MIN) / (MaxVoltage - MinVoltage)) * 100
        
        return soc
        