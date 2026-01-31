"""
LIN Serial Recorder
Records all read and write operations for playback through device.py
"""

import json
import time
import atexit
import logging
import signal
import threading

class LinRecorder:
    def __init__(self, output_file, autosave_interval=0.5):
        self.output_file = output_file
        self.start_time = time.time()
        self.chunks = []
        self.enabled = True
        self.log = logging.getLogger(__name__)
        self._save_lock = threading.Lock()
        self._saved = False
        self._last_save = 0.0
        self._autosave_interval = autosave_interval

        # Register cleanup to save on exit
        atexit.register(self.save)

        # Handle signals to ensure saving on shutdown
        try:
            signal.signal(signal.SIGINT, self._handle_signal)
            signal.signal(signal.SIGTERM, self._handle_signal)
        except Exception:
            pass

        self.log.info(f"LinRecorder initialized: {output_file}")

    def record_read(self, data: bytes):
        """Record data read from serial port (device → app)"""
        if not self.enabled or not data:
            return

        timestamp = time.time() - self.start_time
        self.chunks.append({
            "timestamp": timestamp,
            "direction": "in",
            "data": data.hex()
        })
        self._autosave_if_needed()

    def record_write(self, data: bytes):
        """Record data written to serial port (app → device)"""
        if not self.enabled or not data:
            return

        timestamp = time.time() - self.start_time
        self.chunks.append({
            "timestamp": timestamp,
            "direction": "out",
            "data": data.hex()
        })
        self._autosave_if_needed()

    def save(self, final=True):
        """Save recorded data to JSON file"""
        with self._save_lock:
            if final and self._saved:
                return

            if not self.chunks:
                if final:
                    self.log.info("No data recorded, skipping save")
                return

            try:
                with open(self.output_file, 'w') as f:
                    json.dump({"chunks": self.chunks}, f, indent=2)
                self._last_save = time.time()
                if final:
                    self._saved = True
                self.log.info(f"✓ Saved {len(self.chunks)} chunks to {self.output_file}")
            except Exception as e:
                self.log.error(f"✗ ERROR saving recording: {e}")

    def _handle_signal(self, signum, frame):
        """Save recording on SIGINT/SIGTERM"""
        self.save(final=True)

    def _autosave_if_needed(self):
        if self._autosave_interval is None:
            return
        if self._autosave_interval <= 0:
            self.save(final=False)
            return
        now = time.time()
        if now - self._last_save >= self._autosave_interval:
            self.save(final=False)

    def disable(self):
        """Stop recording"""
        self.enabled = False
