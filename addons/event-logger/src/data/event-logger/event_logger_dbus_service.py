#!/usr/bin/env python3

import argparse
import logging
import os
import sys

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

SERVICE_NAME = "com.victronenergy.settings"
WATCH_PATH = "/Settings/EventLogger/Log" # add loPg num in main below
BUS_ITEM_IFACE = "com.victronenergy.BusItem"
LOG_FORMAT = "%(asctime)s INFO:%(message)s"
# --path /Settings/EventLogger/Log1 --format "%(asctime)s INFO:%(message)s" --logfile "/var/log/event-logger/somefile" ?
# --path /Settings/EventLogger/Log2 --format "%(asctime)s ERROR:%(message)s" --logfile "/var/log/event-logger/somefile" ?

class DBusPathLogger:
    def __init__(self, watch_path):
        self.bus = dbus.SessionBus() if "DBUS_SESSION_BUS_ADDRESS" in os.environ else dbus.SystemBus()
        self.owner = None
        self.watch_path = watch_path

    def start(self):
        self.bus.add_signal_receiver(
            self._on_properties_changed,
            dbus_interface=BUS_ITEM_IFACE,
            signal_name="PropertiesChanged",
            bus_name=SERVICE_NAME,
            path=self.watch_path,
            sender_keyword="sender",
        )

        self.bus.add_signal_receiver(
            self._on_items_changed,
            dbus_interface=BUS_ITEM_IFACE,
            signal_name="ItemsChanged",
            bus_name=SERVICE_NAME,
            path="/",
            sender_keyword="sender",
        )

        self.bus.add_signal_receiver(
            self._on_name_owner_changed,
            signal_name="NameOwnerChanged",
            dbus_interface="org.freedesktop.DBus",
            path="/org/freedesktop/DBus",
        )

        self._refresh_owner()
        self._log_current_value()

    def _refresh_owner(self):
        try:
            self.owner = str(self.bus.get_name_owner(SERVICE_NAME))
        except dbus.DBusException:
            self.owner = None

    def _on_name_owner_changed(self, name, old_owner, new_owner):
        if str(name) != SERVICE_NAME:
            return

        if new_owner:
            logging.info("Service %s appeared (%s)", SERVICE_NAME, new_owner)
        else:
            logging.info("Service %s disappeared", SERVICE_NAME)

        self.owner = str(new_owner) if new_owner else None

        if self.owner:
            self._log_current_value()

    def _sender_matches(self, sender):
        if sender is None:
            return True
        if self.owner is None:
            self._refresh_owner()
        return self.owner is None or str(sender) == self.owner

    def _on_properties_changed(self, changes, sender=None):
        if not self._sender_matches(sender):
            return

        value = self._extract_value(changes)
        logging.info("%s", self._format_value(value))

    def _on_items_changed(self, items, sender=None):
        if not self._sender_matches(sender):
            return

        if self.watch_path not in items:
            return

        item_changes = items.get(self.watch_path, {})
        value = self._extract_value(item_changes)
        logging.info("%s", self._format_value(value))

    @staticmethod
    def _extract_value(changes):
        if isinstance(changes, dict):
            if "Value" in changes:
                return changes.get("Value")
            if "Text" in changes:
                return changes.get("Text")
        return changes

    @staticmethod
    def _format_value(value):
        # Convert dbus scalar wrappers to plain Python types before logging.
        if isinstance(value, (dbus.String, dbus.ObjectPath, dbus.Signature)):
            return str(value)
        if isinstance(value, dbus.Boolean):
            return bool(value)
        if isinstance(value, (dbus.Byte, dbus.Int16, dbus.Int32, dbus.Int64, dbus.UInt16, dbus.UInt32, dbus.UInt64)):
            return int(value)
        if isinstance(value, dbus.Double):
            return float(value)
        return value

    def _log_current_value(self):
        try:
            obj = self.bus.get_object(SERVICE_NAME, self.watch_path)
            iface = dbus.Interface(obj, dbus_interface=BUS_ITEM_IFACE)
            value = iface.GetValue()
            logging.info("Current value at startup %s: %r", self.watch_path, value)
        except dbus.DBusException as err:
            logging.info("Could not read initial value %s: %s", self.watch_path, err)


def main(log_index):
    logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
    DBusGMainLoop(set_as_default=True)

    watch_path = WATCH_PATH + log_index
    logging.info("Starting D-Bus logger for %s%s", SERVICE_NAME, watch_path)

    logger = DBusPathLogger(watch_path)
    logger.start()

    loop = GLib.MainLoop()
    loop.run()


if __name__ == "__main__":
    try:
        parser = argparse.ArgumentParser(description="Event Logger for D-Bus paths")
        parser.add_argument("--log-index", default="1", help="Log index suffix (default: 1)")
        
        args = parser.parse_args()

        main(args.log_index)
    except KeyboardInterrupt:
        logging.info("Stopped by user")
        sys.exit(0)

