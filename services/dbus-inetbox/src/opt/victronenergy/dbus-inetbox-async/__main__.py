#!/usr/bin/env python3

from gi.repository import GLib
import time
from taskmanager import TaskManager
from argparse import ArgumentParser

import logging
import asyncio
import sys
from inetbox_service import InetboxService
import os
from tools import set_app_name

def main():
	appname='dbus-inetbox-async'
	set_app_name(b"dbus-inetbox-a")
	GLib.set_application_name(appname)
 
	log = logging.getLogger("main")

	# "--serial /dev/ttyUSB0 --debug_lin --debug_inet"
	parser = ArgumentParser(description='truma-inetbox', add_help=True)
	parser.add_argument('-di', '--debug_inet', help='enable debug logging of the inetbox app',
											action='store_true')
	parser.add_argument('-dl', '--debug_lin', help='enable debug logging of the lin bus',
											action='store_true')
	parser.add_argument('-s', '--serial', help='tty')
	parser.add_argument('-r', '--record', help='record serial traffic to file')

	args = parser.parse_args()
	if not args.serial:
		log.error('No serial port specified, see -h')
		exit(1)

	counter=0
	while (counter < 10):
		if os.path.exists(args.serial):
			break
		counter +=1
		time.sleep(0.5)
	
	if counter==10:
		log.info("serial port not found")
		return

	serial_port = args.serial
	debug_lin= args.debug_lin
	debug_inet = args.debug_inet
	record_file = args.record
	#debug_lin = True
 
	logging.basicConfig(
		level=logging.DEBUG,
		#format="%(asctime)s - %(levelname)s - %(message)s",
		format="%(levelname)s - %(message)s",
		handlers=[logging.StreamHandler(sys.stdout)],
	)

	log.info('Using serial port: ' + args.serial)
	log.info('debug_lin: ' + str(args.debug_lin))
	log.info('debug_inet: ' + str(args.debug_inet))
	if record_file:
		log.info('Recording to: ' + record_file)
  
	from dbus.mainloop.glib import DBusGMainLoop

	DBusGMainLoop(set_as_default=True)

	async def dbus_loop():
 
		log.info("Connected to dbus, and switching over to GLib.MainLoop() (= event based)")
		
		mainloop = GLib.MainLoop()
  
		# Run mainloop in executor to avoid blocking asyncio
		loop = asyncio.get_event_loop()
		await loop.run_in_executor(None, mainloop.run)
 
	tasks = TaskManager()
	tasks.add_task("dbus_loop", dbus_loop)

	InetboxService(tasks, serial_port, debug_lin, debug_inet, record_file)

	loop = asyncio.new_event_loop()
	asyncio.set_event_loop(loop)

	try:
		asyncio.run(tasks.main_loop())
 
	except KeyboardInterrupt:
		log.info("Shutting down...")
	finally:
		log.info("quitting...")
 
if __name__ == "__main__":
	main()


