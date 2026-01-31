#!/usr/bin/env python3

from gi.repository import GLib
import time
from taskmanager import TaskManager
from argparse import ArgumentParser

import logging
import asyncio
import sys
import threading
from inetbox_service import InetboxService
import os

def main():

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
		time.sleep(1)
	
	if counter==10:
		log.info("serial port not found")
		return

	logging.basicConfig(
		level=logging.DEBUG,
		format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
		handlers=[logging.StreamHandler(sys.stdout)],
	)

	serial_port = args.serial
	debug_lin= args.debug_lin
	debug_inet = args.debug_inet
	record_file = args.record
	#debug_lin = True
  
	log.info('Using serial port: ' + args.serial)
	log.info('debug_lin: ' + str(args.debug_lin))
	log.info('debug_inet: ' + str(args.debug_inet))
	if record_file:
		log.info('Recording to: ' + record_file)

	#from dbus.mainloop.glib import DBusGMainLoop
	# Have a mainloop, so we can send/receive asynchronous calls to and from dbus
	#DBusGMainLoop(set_as_default=True)
 
	tasks = TaskManager()
	
	inetboxService = InetboxService(tasks, serial_port, debug_lin, debug_inet, record_file)
 
	loop = asyncio.new_event_loop()
	asyncio.set_event_loop(loop)
 
	log.info("Connected to dbus, and switching over to GLib.MainLoop() (= event based)")

	try:
		asyncio.run(tasks.main_loop())
 
		#loop.run_forever()
	except KeyboardInterrupt:
		log.info("Shutting down...")
	finally:
		log.info("quitting...")
		#mainloop.quit()
 
if __name__ == "__main__":
	main()


