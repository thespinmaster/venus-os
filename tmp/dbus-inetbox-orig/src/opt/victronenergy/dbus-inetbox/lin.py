# MIT License
# 
# Copyright (c) 2022  Dr. Magnus Christ (mc0110)
#
#
# version 0.8.2
#
# this project is based on the LIN Specification Package Revision 2.2A
#
# The essential basis is to incorporate the results of the specification in such a way that 
# there are no performance problems. Therefore, for example, RAW PIDs are processed in which 
# the parity bits have not been separated. These are shown on pages 53ff of the specification. 
# Thus 3C/3D with parity becomes 3C/7D. If this leads to confusion, I apologise.
# Same approach for the raw PID 0xD8. This corresponds to a PID 0x18
# This module has been optimised for high performance.  

# Required packages:
# pip install pyserial-asyncio

import asyncio
import logging
import sys
from asyncio.transports import WriteTransport
from typing import cast

import serial_asyncio

import inetboxapp
from tools import calculate_checksum


class Lin(asyncio.Protocol):
	log = logging.getLogger(__name__)

	# Only for display control / slow event timing
	CNT_ROWS_MAX = 200
	
	# Check Alive-status periodically - with 1ms delay it is appx. 9s
	# there must be more than 1 D8-requests in this periode, than is alive status "ON"
	# otherwise it would set "OFF" 
	CNT_IN_MAX = 9000
	
	DISPLAY_STATUS_PIDS = [0x20, 0x61, 0xE2]
	
	# the correct (full) preamble starts in the first frame, but we see only one type of
	# frames, all with the same length - so we can use a frame-preamble with a shorter length,
	# starting in the 2. frame
	BUFFER_PREAMBLE = bytes([0x00, 0x00, 0x22, 0xFF, 0xFF, 0xFF, 0x54, 0x01])

	BUFFER_HEADER_RECV  = bytes([0x14, 0x33])
	BUFFER_HEADER_TIMER = bytes([0x18, 0x3D])
	BUFFER_HEADER_02    = bytes([0x02, 0x0D])
	BUFFER_HEADER_03    = bytes([0x0A, 0x15])
	BUFFER_HEADER_WRITE = bytes([0x0C, 0x32])

	def __init__(self, app: inetboxapp.InetboxApp, port: str, lin_debug: bool):
		self.app = app
		self.port = port
		self.lin_debug = lin_debug
		
		# asyncio
		self.transport: WriteTransport | None = None
		self.rx_buffer = bytearray()
		
		# instance-local state
		self.ts_response_buffer: list[bytes] = []
		self.cpp_in_buffer = [bytes([]) for _ in range(6)]
		self.cpp_buffer: dict[bytes, bytes] = {}
		self.cmd_buf = {}
		
		self.updates_to_send = False
		self.update_request = False
		self.stop_async = False
		self.cnt_rows = 1
		self.cnt_in = 0
		self.d8_alive = False
		self.done = False
		
		if lin_debug:
			self.log.setLevel(logging.DEBUG)
		else:
			self.log.setLevel(logging.INFO)
		
		self.log.info("Lin initialized")

	# Connection lifecycle
	async def connect(self):
		"""Establish serial connection using serial_asyncio."""
		await serial_asyncio.create_serial_connection(
			asyncio.get_running_loop(),
			lambda: self,
			self.port,
			baudrate=9600,
			bytesize=8,
			parity="N", 
			stopbits=1,
			xonxoff=False,
			rtscts=False,
			dsrdtr=False
		)

	def connection_made(self, transport):
		"""Called when connection is established."""
		self.transport = cast(WriteTransport, transport)
		self.log.info("Serial connection established")

	def connection_lost(self, exc):
		"""Called when connection is lost."""
		self.log.error("Serial connection lost")
		if exc:
			self.log.exception(exc)

	def close(self):
		"""Close the serial connection."""
		if self.transport:
			self.log.info("Closing serial transport")
			self.transport.close()
			self.transport = None

	# TX helpers

	def response_waiting(self) -> int:
		return len(self.ts_response_buffer)

	def _send_answer(self, databytes: bytes):
		if self.transport:
			self.transport.write(databytes)
			self.log.debug(f"out > {databytes.hex(' ')}")

	def _send_answer_str(self, data_str: str):
		self.log.debug(f"_send_answer_str:{data_str}")
		self._send_answer(bytes.fromhex(data_str.replace(" ", "")))

	def _send_answer_w_cs_calc(self, databytes: bytes, pid_for_checksum=None):
		if pid_for_checksum is None:
			cs = calculate_checksum(databytes)
		else:
			cs = calculate_checksum(bytes([pid_for_checksum]) + databytes)
		self._send_answer(databytes + bytes([cs]))

	def prepare_tl_response(self, messages: bytes):
		self.log.debug(f"prepare_tl_response")
		self.ts_response_buffer.append(messages)

	def prepare_tl_str_response(self, message_str: str, info_str: str):
		self.log.debug(f"prepare_tl_str_response")
		self.prepare_tl_response(bytes.fromhex(message_str.replace(" ", "")))
		if info_str.startswith("_"):
			self.log.debug(info_str)
		else:    
			self.log.info(info_str)

	def _answer_tl_request(self):
		self.log.debug(f"_answer_tl_request")
		if self.ts_response_buffer:
			databytes = bytes(self.ts_response_buffer.pop(0))
			self._send_answer(databytes)
		else:
			self.log.debug("unexpacted behavior - nothing to send")

	# RX handling

	def data_received(self, data: bytes):
		"""Called when data is received from the serial port."""
		self.log.debug(f"RX raw: {data.hex(' ')} ({len(data)} bytes)")
		self.rx_buffer.extend(data)
		self._process_rx()

	def _process_rx(self):
		"""Process received data byte by byte."""
		# Call status_monitor at the start of each processing cycle
		self.status_monitor()

		self.log.debug(f"Processing buffer: {self.rx_buffer[:20].hex(' ')}... ({len(self.rx_buffer)} bytes)")

		while len(self.rx_buffer) > 0:
			# Search for 0x55 sync byte in the stream
			if self.rx_buffer[0] != 0x55:
				self.log.debug(f"Discarding non-sync byte: {self.rx_buffer[0]:02x}")
				self.rx_buffer.pop(0)
				continue

			# Found 0x55 - need at least 3 bytes to check PID
			if len(self.rx_buffer) < 3:
				self.log.debug("Waiting for more data (need PID)")
				break

			raw_pid = self.rx_buffer[1]
			self.log.debug(f"Found 0x55, PID: {raw_pid:02x}")

			# Check for display status PIDs (diagnostic)
			if raw_pid in self.DISPLAY_STATUS_PIDS:
				self.log.debug(f"Status PID detected: {raw_pid:02x}")

			# Alive probe (0xD8) - original code only consumes 3 bytes, leaves rest to be discarded
			if raw_pid == 0xD8:
				# Need at least 3 bytes (0x55, PID, first data byte)
				if len(self.rx_buffer) < 3:
					self.log.debug("Waiting for PID byte after 0xD8")
					break
				self.log.debug("Handling 0xD8 alive probe")
				self._handle_alive_probe()
				del self.rx_buffer[:3]  # Only consume sync + PID + 1 byte, rest gets discarded
				return

			# TL response request (0x7D) - original code only consumes 3 bytes, leaves rest to be discarded
			if raw_pid == 0x7D:
				# Need at least 3 bytes (0x55, PID, first data byte)
				if len(self.rx_buffer) < 3:
					self.log.debug("Waiting for PID byte after 0x7D")
					break
				self.log.debug("Handling 0x7D TL response")
				if self.response_waiting():
					self._answer_tl_request()
				else:
					self.log.debug("No response waiting for 0x7D")
				del self.rx_buffer[:3]  # Only consume sync + PID + 1 byte, rest gets discarded
				return

			# Full frame requires 11 bytes (starting with 0x55)
			if len(self.rx_buffer) < 12:
				self.log.debug(f"Waiting for full frame (have {len(self.rx_buffer)}, need 11)")
				break

			frame = bytes(self.rx_buffer[:12])
			self.log.debug(f"Processing full frame: {frame.hex(' ')}")
			del self.rx_buffer[:12]
			self._handle_frame(frame)

	def _handle_alive_probe(self):
		"""Handle the 0xD8 alive probe."""
		self.log.debug(f"_handle_alive_probe")
		self.d8_alive = True
		if self.app.status["alive"][0] != "ON":
			self.app.status["alive"] = ["ON", True, False]

		send_upload = False
		if not self.app.upload_wait:
			send_upload = self.app.upload_buffer or self.app.upload02_buffer

		if send_upload:
			self.app.upload_wait = 4
			self.stop_async = True
			self.log.debug("0x18 - update-requested")
			self._send_answer(bytearray.fromhex("ff ff ff ff ff ff ff ff 27".replace(" ", "")))
		else:
			self._send_answer(bytearray.fromhex("fe ff ff ff ff ff ff ff 28".replace(" ", "")))
			if self.app.upload_wait:
				self.app.upload_wait -= 1


	def _handle_frame(self, frame: bytes):
		"""Handle a received 11-byte frame (starting with 0x55)."""
		self.log.debug(f"in < {frame.hex(' ')}")

		# Trigger events based on frame count (for timing)
		self.cnt_rows += 1
		self.cnt_rows = self.cnt_rows % self.CNT_ROWS_MAX
		if not self.cnt_rows:
			self.display_status()

		# Prepend 0x00 to match original frame format (original code artificially prepended this)
		# This gives us format: [0x00, 0x55, PID, ...]
		frame_with_prefix = bytes([0x00]) + frame

		# Check for multi-frame buffer download from CPplus
		# Frame format: [0x00, 0x55, 0x3c, 0x03, segment_id, data...]
		buf_trans_id = bytes([0x00, 0x55, 0x3c, 0x03])
		if frame_with_prefix[:4] == buf_trans_id and frame_with_prefix[4] in range(0x21, 0x27):
			# Store this segment in the buffer
			self.cpp_in_buffer[frame_with_prefix[4] - 0x21] = frame_with_prefix[5:-1]
			
			# If this is the last segment (0x26), assemble the complete buffer
			if frame_with_prefix[4] == 0x26:
				if self.assemble_cpp_buffer():
					self.prepare_tl_str_response("03 01 fb ff ff ff ff ff 00", "_send ackn-response for buffer delivery")
			return

		# Check for done flag
		if self.done == 2:
			return

		cmd = frame_with_prefix.hex(" ")
		handler = CMD_CTRL.get(cmd)

		if not handler:
			self.log.debug(f"Unhandled frame: {cmd}")
			return

		fn, arg1, arg2 = handler
		self.log.debug(f"CMD_CTRL:{cmd},{arg1},{arg2}")
		fn(self, arg1, arg2)

	# Protocol logic

	def no_answer(self, s, p):
		self.log.debug(f"no_answer")
		if self.stop_async:
			self.stop_async = self.response_waiting()
		self.updates_to_send = (self.app.upload_buffer or self.app.upload02_buffer)
		if p.startswith("_"): 
			return
		self.log.debug(p)

	def display_status(self):
		pass

	def assemble_cpp_buffer(self):
		self.log.debug(f"assemble_cpp_buffer")
		"""Assemble buffer from received segments."""
		buf = bytes([])
		for i in range(5):
			buf += self.cpp_in_buffer[i]
		
		if buf[:8] != self.BUFFER_PREAMBLE:
			self.log.debug("buffer preamble doesn't match")
			return False
		
		buf_id = buf[8:10]
		self.d8_alive = True
		self.cpp_buffer[buf_id] = buf[10:]
		self.log.debug(f"Buf[{buf_id}]={self.cpp_buffer[buf_id]}")
		self.app.process_status_buffer_update(buf_id, self.cpp_buffer[buf_id])
		return True

	def generate_inet_upload(self, s, p):
		"""Generate and prepare inetBox upload in response to device request."""
		if self.app.upload_buffer:
			self.log.debug("heater_status to be generated")
			self.cmd_buf = self.app._get_status_buffer_for_writing()
			self.stop_async = True
			if self.app.upload_buffer > 0: 
				self.app.upload_buffer -= 1

		if self.app.upload02_buffer:
			self.log.debug("aircon_status to be generated")
			self.cmd_buf = self.app._get_status_buffer1_for_writing()
			self.stop_async = True
			if self.app.upload02_buffer > 0: 
				self.app.upload02_buffer -= 1

		if (self.cmd_buf is None) or (self.cmd_buf == {}):
			self.log.debug("cmd_buffer is empty")
			return
		
		self.d8_alive = True
		self.stop_async = True
		for i in self.cmd_buf:
			self.prepare_tl_response(i)
		self.updates_to_send = False
		if p.startswith("_"): 
			return
		self.log.debug(p)

	# check alive status
	def status_monitor(self):
		self.cnt_in += 1
		
		if not(self.cnt_in % self.CNT_IN_MAX):
			self.cnt_in = 0
			self.app.status["alive"] = ["ON", True, False] 
			# Same approach for the raw PID 0xD8. This corresponds to a PID 0x18
			if self.d8_alive:
				self.app.status["alive"][0] = "ON"
			else:    
				self.app.status["alive"][0] = "OFF"
			self.d8_alive = False

	async def watchdog(self):
		"""Watchdog timer - reboot system if device not responding."""
		self.log.info("watchdog activated")
		await asyncio.sleep(60)
		if (self.app.status["alive"][0] == "ON"):
			self.log.info("watchdog deactivated_s1")
			return
		await asyncio.sleep(60)
		if (self.app.status["alive"][0] == "ON"):
			self.log.info("watchdog deactivated_s2")
			return
		await asyncio.sleep(60)
		if (self.app.status["alive"][0] == "ON"):
			self.log.info("watchdog deactivated_s3")
		else:
			if self.lin_debug:
				self.log.debug("system reboot in debug_mode suppressed")
			else:    
				self.log.info("system reboot required")
				#sys.exit(1)


# Command control dictionary for frame handling
CMD_CTRL = {
	"00 55 3c 7f 06 b2 00 17 46 00 1f 4b": [Lin.prepare_tl_str_response, "03 06 f2 17 46 00 1f 00 87", "_B2 - response request"],  # B2-Message I - Initialization started
	"00 55 03 aa 0a ff ff ff ff ff ff 48": [Lin.no_answer, "", "_NAD 03 response - ack"],               # reaction to B2 - ackn
	"00 55 3c 03 06 b2 20 17 46 00 1f a7": [Lin.prepare_tl_str_response, "03 06 f2 17 46 00 1f 00 87", "B2 - identifier for NAD 03"],  # B2-Message II: Looking for my ID-no 17 46 00 1f
	"00 55 3c 03 06 b2 22 17 46 00 1f a5": [Lin.prepare_tl_str_response, "03 06 f2 17 46 00 1f 00 87", "B2 - initializer for NAD 03   -----------------> start registration"],  # B2-Message Initializer		
	"00 55 3c 7f 06 b0 17 46 00 1f 03 4a": [Lin.prepare_tl_str_response, "03 01 f0 ff ff ff ff ff 0b", "B0 - init finalized - send ackn ---------------> registration finalized"],  # B0-Message - registation finalized
	"00 55 3c 03 05 b9 00 1f 00 00 ff 1f": [Lin.prepare_tl_str_response, "03 02 f9 00 ff ff ff ff 01", "_Heartbeat for NAD 03 - send response"],  # Heartbeat
	"00 55 3c 03 10 29 bb 00 1f 00 1e ca": [Lin.no_answer, "", "_Frame 1 of buffer-transfer (6 frames) from CPplus"], #0xBB notice to send buffer
	"00 55 3c 03 10 0b ba 00 1f 00 1e e9": [Lin.generate_inet_upload, "", "BA-request: upload started"], # 0xBA request for inetBox to upload the buffer-frames
	"00 55 03 aa 0a ff ff ff ff ff ff 48": [Lin.no_answer, "", "_ackn from CPplus"], # ackn from CPplus
}

# CMD_CTRL integrity check (FAIL FAST)
for cmd, (fn, _, _) in CMD_CTRL.items():
	if not hasattr(Lin, fn.__name__):
		raise RuntimeError(
			f"CMD_CTRL references missing Lin method: {fn.__name__}"
		) 

