#!/usr/bin/env python3

from gi.repository import GLib
import time
from argparse import ArgumentParser

import logging
import asyncio
import sys
import threading
from inetbox_service import InetboxService
 
def main():
 
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
		level=logging.DEBUG,
		format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
		handlers=[logging.StreamHandler(sys.stdout)],
	)
 
	serial_port = args.serial
 
	debug_lin= args.debug_lin
	debug_inet = args.debug_inet

	log.info('Using serial port: ' + args.serial)
	log.info('debug_lin: ' + str(args.debug_lin))
	log.info('debug_inet: ' + str(args.debug_inet))
 
	inetboxService = InetboxService(serial_port, debug_lin, debug_inet)
	lin = inetboxService._lin
 
	log.info("Starting LIN service with serial_asyncio")

	try:
		asyncio.run(run_service(lin, inetboxService._app))
	except Exception as ex:
		log.error("Exception... {ex}")
	finally:
		log.info("quitting...")
		lin.close()

async def run_service(lin, app):
	"""Run the LIN service with async operations."""
	log = logging.getLogger("main")
	
	try:
		# Establish serial connection
		await lin.connect()
		
		# Create and run background tasks
		watchdog_task = asyncio.create_task(lin.watchdog())
		publish_task = asyncio.create_task(app._publish_loop())
		
		# Wait for all tasks (data_received() callback handles incoming data automatically)
		await asyncio.gather(watchdog_task, publish_task)
	except Exception as e:
		log.error(f"Error in service: {e}")
		raise

if __name__ == "__main__":
	main()