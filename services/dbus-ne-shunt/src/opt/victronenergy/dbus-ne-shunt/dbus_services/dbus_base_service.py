#!/usr/bin/env python3

"""
A class to put a simple service on the dbus, according to victron standards, with constantly updating
paths. See example usage below. It is used to generate dummy data for other processes that rely on the
dbus. See files in dbus_vebus_to_pvinverter/test and dbus_vrm/test for other usage examples.

To change a value while testing, without stopping your dummy script and changing its initial value, write
to the dummy data via the dbus. See example.

https://github.com/victronenergy/dbus_vebus_to_pvinverter/tree/master/test
"""

from gi.repository import GLib
import platform
import logging
import os
from dbus_constants import dbus_constants
from dbus_connection import dbusconnection
from ext.vedbus import VeDbusService

class dbus_base_service(object):
 
    # Create the mandatory objects
    def unregister(self):
        """
        Unregister the dbus service.
        """
        if self._dbusservice:
            self._dbusservice.__del__()
            self._dbusservice = None
            logging.debug("Unregistered %s" % (self._dbusservice))
        else:
            logging.debug("No dbus service to unregister")
            
    def _registerCore(self, port, classAndVrmInstance, paths, onValueChanged = None):
        
        logging.debug("_registerCore in")

        portName = os.path.basename(port) # convery from /dev/ttyxxx to ttyxxx
        classAndVrmInstanceParts = classAndVrmInstance.split(':')
        className = classAndVrmInstanceParts[0]
        deviceInstance = int(classAndVrmInstanceParts[1]) #!IMPORTANT MUST BE AN INT

        serviceName = "com.victronenergy.{}.{}_id_{}.{}".format(className, dbus_constants.PRODUCT_NAME, 
                                                                deviceInstance, portName)

        self._dbusservice = VeDbusService(serviceName, bus=dbusconnection(), register=False)
  
        self._paths = paths
        self._dbusservice
 
        logging.debug(f"{serviceName} /DeviceInstance = {classAndVrmInstance}")

        # Create the management objects, as specified in the ccgx dbus-api document
        self._dbusservice.add_mandatory_paths(__file__,
            'Unknown version, and running on Python ' + platform.python_version(),
            portName,
            deviceInstance,
            dbus_constants.PRODUCT_ID,
            dbus_constants.PRODUCT_NAME,
            dbus_constants.FIRMWARE_VERSION,
            dbus_constants.HARDWARE_VERSION,
            1)
        
        self._dbusservice.add_path("/ServiceName", "dbus-ne-shunt")

        for path, settings in self._paths.items():
            self._dbusservice.add_path(
                path, 
                value = settings[dbus_constants.PATH_SETTING_INITIAL],
                writeable = settings[dbus_constants.PATH_SETTING_WRITABLE], 
                onchangecallback = onValueChanged)
        
        self._dbusservice.register()
        

    def get_value(self, path):
        """
        Get the value of a path.
        """
        with self._dbusservice as s:
            return s[path]
    
    
    def set_value(self, path, value):
        """
        Set the value of a path.
        """
        with self._dbusservice as s:
            s[path] = value
            logging.debug("Set %s to %s" % (path, value))
        return True
 

