#!/usr/bin/env python3

import argparse
import logging
import os
import sys

try:
    import paho.mqtt.client as mqtt
    from paho.mqtt.enums import CallbackAPIVersion
except ImportError as err:
    print("Missing dependency: paho-mqtt (python3-paho-mqtt).", file=sys.stderr)
    raise SystemExit(1) from err


LOG_FORMAT = "%(asctime)s INFO:%(message)s"
BROKER_HOST = os.getenv("MQTT_BROKER_HOST", "127.0.0.1")
BROKER_PORT = int(os.getenv("MQTT_BROKER_PORT", "1883"))
KEEPALIVE_SECONDS = int(os.getenv("MQTT_KEEPALIVE", "60"))
DEFAULT_WATCH_TOPIC = os.getenv("MQTT_WATCH_TOPIC", "settings/0/Settings/EventLogger/Log")


class MQTTTopicLogger:
    def __init__(self, topic):
        self.topic = topic
        self.client = mqtt.Client(CallbackAPIVersion.VERSION2)
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.client.on_message = self._on_message

    def start(self):
        logging.info(
            "Starting MQTT logger on %s:%s, topic %s",
            BROKER_HOST,
            BROKER_PORT,
            self.topic,
        )
        self.client.connect(BROKER_HOST, BROKER_PORT, KEEPALIVE_SECONDS)
        self.client.loop_forever()

    def _on_connect(self, client, userdata, flags, reason_code, properties):
        if reason_code != 0:
            logging.info("MQTT connect failed: rc=%s", reason_code)
            return

        result, _ = client.subscribe(self.topic)
        if result == mqtt.MQTT_ERR_SUCCESS:
            logging.info("Subscribed to %s", self.topic)
        else:
            logging.info("Subscribe failed for %s: %s", self.topic, result)

    @staticmethod
    def _on_disconnect(client, userdata, disconnect_flags, reason_code, properties):
        logging.info("Disconnected from MQTT broker: rc=%s", reason_code)

    @staticmethod
    def _on_message(client, userdata, msg):
        payload = msg.payload
        try:
            payload_text = payload.decode("utf-8")
        except Exception:
            payload_text = repr(payload)
        logging.info("%s", payload_text)


def main():
    parser = argparse.ArgumentParser(description="Event Logger for MQTT topics")
    parser.add_argument("--device-id", required=True, help="Device ID for MQTT topic")
    parser.add_argument("--log-index", default="1", help="Log index suffix (default: 1)")
    
    args = parser.parse_args()
    
    watch_topic = f"N/{args.device_id}/{DEFAULT_WATCH_TOPIC}{args.log_index}"
    
    logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
    logging.info("Starting MQTT logger with device-id=%s, log-index=%s", args.device_id, args.log_index)

    logger = MQTTTopicLogger(watch_topic)
    logger.start()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Stopped by user")
        sys.exit(0)
