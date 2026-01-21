#!/usr/bin/env python3
 
from taskmanager import TaskManager
from lin import Lin
from inetboxapp import InetboxApp
from argparse import ArgumentParser
import logging
import asyncio
import sys
import threading
from mqtt import Mqtt

global app
global lin

def main():
	global app
	global lin

	log = logging.getLogger("main")

	# "--serial /dev/ttyUSB0 --debug_lin --debug_inet"
	parser = ArgumentParser(description='truma-inetbox', add_help=True)
	parser.add_argument('-di', '--debug_inet', help='enable debug logging of the inetbox app',
											action='store_true')
	parser.add_argument('-dl', '--debug_lin', help='enable debug logging of the lin bus',
											action='store_true')
	parser.add_argument('-s', '--serial', help='tty')

	args = parser.parse_args()
	if not args.serial:
		log.error('No serial port specified, see -h')
		exit(1)

	logging.basicConfig(
		level=logging.ERROR,
		format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
		handlers=[logging.StreamHandler(sys.stdout)],
	)
 
	serial_port = args.serial
	if not serial_port.startswith("/dev/"):
		serial_port="/dev/" + serial_port
 
	debug_lin = args.debug_lin
	debug_inet = args.debug_inet

	log.info('Using serial port: ' + args.serial)
	log.info('debug_lin: ' + str(args.debug_lin))
	log.info('debug_inet: ' + str(args.debug_inet))

	tasks = TaskManager()
	app = InetboxApp(tasks, debug_inet)  
	lin = Lin(app, serial_port, tasks, debug_lin)

	mqtt_publisher = Mqtt()
	app.add_publish_callback(mqtt_publisher.publish)
	
	loop = asyncio.get_event_loop()
	
	try:
			#threading.Timer(10.0, setHeating).start()
		loop.run_until_complete(tasks.main_loop())
		loop.run_forever()
	except KeyboardInterrupt:
		log.info("Shutting down...")
	finally:
		loop.close()
 
 
def setHeating():
	global lin
	app.set_status("target_temp_room",22)

	threading.Timer(5.0, setHeating).start()

if __name__ == "__main__":
	main()


