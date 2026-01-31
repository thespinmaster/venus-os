#!/usr/bin/env python3
"""
Record serial port data bidirectionally while acting as transparent proxy.
Usage: python3 serial-recorder.py /dev/ttyUSB0 /dev/pts/X output.json
"""

import serial
import sys
import time
import json
import threading
import os
import signal

class RecordingProxy:
    def __init__(self, real_port, virtual_port, output_file):
        self.real_serial = serial.Serial(real_port, 9600, timeout=0.01)
        self.virtual_serial = serial.Serial(virtual_port, 9600, timeout=0.01)
        self.output_file = output_file
        self.start_time = time.time()
        self.chunks = []
        self.running = True
        
    def run(self):
        print(f"Proxy running: {self.real_serial.port} <-> {self.virtual_serial.port}")
        print(f"Recording to: {self.output_file}")
        print("Press Ctrl+C to stop\n")
        
        # Start two threads for bidirectional communication
        thread_device_to_app = threading.Thread(target=self._forward_device_to_app, daemon=True)
        thread_app_to_device = threading.Thread(target=self._forward_app_to_device, daemon=True)
        
        thread_device_to_app.start()
        thread_app_to_device.start()
        
        try:
            while self.running:
                time.sleep(0.1)
        except KeyboardInterrupt:
            print(f"\n\nRecorded {len(self.chunks)} chunks")
            self.save()
    
    def _forward_device_to_app(self):
        """Forward data from real device to virtual port (app receives)"""
        while self.running:
            try:
                if self.real_serial.in_waiting > 0:
                    data = self.real_serial.read(self.real_serial.in_waiting)
                    if data:
                        # Forward to app immediately
                        self.virtual_serial.write(data)
                        self.virtual_serial.flush()
                        
                        # Record it
                        timestamp = time.time() - self.start_time
                        self.chunks.append({
                            "timestamp": timestamp,
                            "direction": "in",
                            "data": data.hex()
                        })
                        print(f"[DEVICE→APP] {len(data):4d} bytes: {data.hex(' ')}")
                else:
                    time.sleep(0.001)
            except Exception as e:
                print(f"ERROR in device_to_app: {e}")
                time.sleep(0.01)
    
    def _forward_app_to_device(self):
        """Forward data from virtual port to real device (app sends)"""
        while self.running:
            try:
                if self.virtual_serial.in_waiting > 0:
                    data = self.virtual_serial.read(self.virtual_serial.in_waiting)
                    if data:
                        # Forward to device immediately
                        self.real_serial.write(data)
                        self.real_serial.flush()
                        
                        # Record it
                        timestamp = time.time() - self.start_time
                        self.chunks.append({
                            "timestamp": timestamp,
                            "direction": "out",
                            "data": data.hex()
                        })
                        print(f"[APP→DEVICE] {len(data):4d} bytes: {data.hex(' ')}")
                else:
                    time.sleep(0.001)
            except Exception as e:
                print(f"ERROR in app_to_device: {e}")
                time.sleep(0.01)
    
    def stop(self):
        self.running = False
        
    def save(self):
        with open(self.output_file, 'w') as f:
            json.dump({"chunks": self.chunks}, f, indent=2)
        print(f"\nSaved to {self.output_file}")

def signal_handler(sig, frame):
    sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python serial-recorder.py <real_port> <virtual_port> <output.json>")
        print("Example: python serial-recorder.py /dev/ttyUSB0 /dev/pts/4 recording.json")
        sys.exit(1)
    
    signal.signal(signal.SIGINT, signal_handler)
    
    proxy = RecordingProxy(sys.argv[1], sys.argv[2], sys.argv[3])
    proxy.run()