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

from dbus_connection import dbusconnection
from ext.vedbus import VeDbusService

class dbus_base_service(object):
	
	_dbusservice = None

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
	
		  
	def _registerCore(self, connection:str, 
                   deviceInstance: int, 
                   serviceName:str, 
                   productId:int,
                   productName:str,
                   firmwareVersion:str,
                   hardwareVersion:str,
                   paths, onValueChanged = None):
		
		logging.debug("_registerCore in")

		self._dbusservice = VeDbusService(serviceName, bus=dbusconnection(), register=False)
  
		self._paths = paths

		# Create the management objects, as specified in the ccgx dbus-api document
		self._dbusservice.add_mandatory_paths(__file__,
			'Unknown version, and running on Python ' + platform.python_version(),
			connection,
			deviceInstance,
			productId,
			productName,
			firmwareVersion,
			hardwareVersion,
			1)
 
		for path, settings in self._paths.items():
			self._dbusservice.add_path(
				path, 
				value = settings["initial"],
				writeable = settings["writable"], 
				onchangecallback = onValueChanged)
		
		self._dbusservice.register()
		

	def get_value(self, path):
		"""
		Get the value of a path.
		"""
		if (self._dbusservice == None):
			return None
		
		return self._dbusservice[path]
	
	
	def set_value(self, path, value):
		"""
		Set the value of a path.
		"""
		if (self._dbusservice == None):
			return False
	
		with self._dbusservice as s:
			s[path] = value
			logging.debug("Set %s to %s" % (path, value))
		return True
 

