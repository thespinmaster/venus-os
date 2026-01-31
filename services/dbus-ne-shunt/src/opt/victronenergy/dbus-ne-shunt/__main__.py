#!/usr/bin/python3 -u

from gi.repository import GLib
import time
import logging
from ne_shunt_service import ne_shunt_service
from argparse import ArgumentParser
import globals

log = logging.getLogger()
 
def main():
  
	parser = ArgumentParser(description="dbus-ne-shunt", add_help=True)
	parser.add_argument(
			"-d", "--debug", help="enable debug logging", action="store_true"
	)
	parser.add_argument(
			"-r", "--readonly", help="only read data from the serial port", action="store_true"
	)
	parser.add_argument(
			"-v", "--verbose", help="output extra logging", action="store_true"
	)
	parser.add_argument("-s", "--serial", help="tty")
 
	args = parser.parse_args()
	if not args.serial:
		log.error("No serial port specified, see -h")
		exit(1)
  
	globals.verbose_logging=args.verbose
	#filename="/data/dbus-ne-shunt.log",
	logging.basicConfig(
		format="%(asctime)s;%(levelname)-8s %(message)s",
		level=(logging.DEBUG if args.debug else logging.INFO),
	)
	
	serial = args.serial
	if not serial.startswith("/dev/"):
		serial="/dev/" + serial
  
	log.info("Serial port:" + serial)

	from dbus.mainloop.glib import DBusGMainLoop

	# Have a mainloop, so we can send/receive asynchronous calls to and from dbus
	DBusGMainLoop(set_as_default=True)
 
	nuss = ne_shunt_service(serial, args.readonly)
	nuss.initialize()

	time.sleep(2)
	GLib.timeout_add(1000, nuss._update)

	log.info("Connected to dbus, and switching over to GLib.MainLoop() (= event based)")

	mainloop = GLib.MainLoop()
	mainloop.run()
  

if __name__ == "__main__":
	main()
