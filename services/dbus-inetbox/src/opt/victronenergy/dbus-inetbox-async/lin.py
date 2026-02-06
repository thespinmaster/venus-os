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
	
import inetboxapp
import serial_asyncio
from taskmanager import TaskManager
from tools import calculate_checksum
from lin_recorder import LinRecorder
import logging
import asyncio
from typing import Optional, cast
 

class LinLogger(logging.Logger):
  
			# Add custom log level for LIN-TRACE
		LIN_TRACE_LEVEL = 15  # Between INFO (20) and DEBUG (10)
		logging.addLevelName(LIN_TRACE_LEVEL, "LIN-TRACE")

		def lin_trace(self, message, *args, **kwargs):
				if self.isEnabledFor(self.LIN_TRACE_LEVEL):
					self._log(self.LIN_TRACE_LEVEL, message, args, **kwargs)

logging.setLoggerClass(LinLogger)

class Lin(asyncio.Protocol):

		ts_response_buffer = []
		cpp_in_buffer = [bytes([]),bytes([]),bytes([]),bytes([]),bytes([]),bytes([])]
		updates_to_send = False
		update_request = False
		cpp_buffer = {}
		cmd_buf = {}
 
		stop_async = False
		log: LinLogger = logging.getLogger(__name__)  # type: ignore[assignment]
 
		app : inetboxapp.InetboxApp
		# Same approach for the raw PID 0xD8. This corresponds to a PID 0x18
		d8_alive = False
 
		# Check Alive-status periodically - with 1ms delay it is appx. 9s
		# there must be more than 1 D8-requests in this periode, than is alive status "ON"
		# otherwise it would set "OFF" 
		# CNT_IN_MAX = 9000
		
		DISPLAY_STATUS_PIDS = [bytes([0x20]), bytes([0x61]), bytes([0xE2])]
		
		
		# the correct (full) preamble starts in the first frame, but we see only one type of
		# frames, all with the same length - so we can use a frame-preamble with a shorter length,
		# starting in the 2. frame
		BUFFER_PREAMBLE = bytes([0x00, 0x00, 0x22, 0xFF, 0xFF, 0xFF, 0x54, 0x01])


		BUFFER_HEADER_RECV  = bytes([0x14, 0x33])
		BUFFER_HEADER_TIMER = bytes([0x18, 0x3D])
		BUFFER_HEADER_02    = bytes([0x02, 0x0D])
		BUFFER_HEADER_03    = bytes([0x0A, 0x15])
		BUFFER_HEADER_WRITE = bytes([0x0C, 0x32])


		def __init__(self, app : inetboxapp.InetboxApp, port : str, tasks : TaskManager, lin_debug, record_file=None):
			self.transport: Optional[asyncio.BaseTransport] = None
			self.loop_state = False
			self.port = port
			
			# Initialize recorder if file specified
			self.recorder = LinRecorder(record_file) if record_file else None
			
			self._rx_buf = bytearray()
 
			if lin_debug:
					self.log.setLevel(logging.DEBUG)
			else:
					self.log.setLevel(logging.INFO)
					
			self.lin_debug = lin_debug    

			self.app = app
			if not(tasks==None):
				tasks.add_task("lin_loop", self._lin_loop)
				tasks.add_task("lin_connect", self.connect)

			print("Lin initialized")
			if self.recorder:
				print(f"Recording enabled: {record_file}")

		# ____________________________________
		# serial_asyncio lambdas
		def connection_made(self, transport):
			self.transport = transport
			self.log.info("Serial connection established")

		def connection_lost(self, exc):
    
			self.log.error("Serial connection lost")
			self.transport = None
			if exc:
				self.log.exception(exc)
    
		def data_received(self, data: bytes):
			if not data:
				return
			if self.recorder:
				self.recorder.record_read(data)
			
			#print(f"[LIN-DEBUGa] RX raw: {data.hex(' ')} ({len(data)} bytes)")
			
			self._rx_buf.extend(data)
			self._process_rx_buffer()
   
		def response_waiting(self):
			return len(self.ts_response_buffer)
 
		# ____________________________________
 


		def _send_answer_str(self, data_str):
			self._send_answer(bytes.fromhex(data_str.replace(" ","")))


		def _send_answer_w_cs_calc(self, databytes, pid_for_checksum=None):
				if not pid_for_checksum:
						cs = calculate_checksum(databytes)
				else:
						cs = calculate_checksum(bytes([pid_for_checksum]) + databytes)
				self._send_answer(databytes.extend([cs]))    


		def _send_answer(self, databytes):
			if self.recorder:
				self.recorder.record_write(databytes)
			if self.transport:
				# Cast to WriteTransport which has the write() method
				transport = cast(asyncio.WriteTransport, self.transport)
				transport.write(databytes)
			else:
				self.log.warning("No transport available; dropping outgoing frame")
				#self.log.debug("out > " + str(databytes.hex(" ")))
			self.log.lin_trace(f"out > {databytes.hex(' ')}")

		def prepare_tl_str_response(self, message_str, info_str):
				self.prepare_tl_response(bytes.fromhex(message_str.replace(" ","")))
				#if info_str.startswith("_"):
				#		self.log.debug(info_str)
				#else:    
				#		self.log.info(info_str)


		def prepare_tl_response(self, messages):
				self.ts_response_buffer.extend([messages])


		def _answer_tl_request(self):
				if len(self.ts_response_buffer):
						databytes = bytes(self.ts_response_buffer[0])
						self.ts_response_buffer.pop(0)
						self._send_answer(databytes)
				else:
						self.log.debug("unexpacted behavior - nothing to send")


		def no_answer(self, s, p):
				if self.stop_async:
						self.stop_async = self.response_waiting()
				self.updates_to_send = (self.app.upload_buffer or self.app.upload02_buffer)
				if p.startswith("_"): return
				#self.log.debug(p)

			 
		def display_status(self):
				pass
		async def connect(self):
			"""Establish and maintain async serial connection."""
			while True:
				if self.transport is None:
					try:
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
							dsrdtr=False,
							timeout=0.003,
						)
					except Exception as exc:
						self.log.error("Serial connection failed")
						self.log.exception(exc)
						await asyncio.sleep(5)
				await asyncio.sleep(1)

		def assemble_cpp_buffer(self):
				# gather the transfered frames 
				# preamble "00 1E 00 00 0x22 0xFF 0xFF 0x54 0x01"
				# buffer id (2 bytes)
				buf = bytes([])
				for i in range(5):
						buf += self.cpp_in_buffer[i]
				#print(buf.hex("+"))    
				if buf[:8] != self.BUFFER_PREAMBLE:
						#self.log.debug("buffer preamble doesn't match")
						return False
				buf_id = buf[8:10]
				self.d8_alive = True
				self.cpp_buffer[buf_id] = buf[10:]
				#self.log.debug(f"Buf[{buf_id}]={self.cpp_buffer[buf_id]}")
				self.app.process_status_buffer_update(buf_id, self.cpp_buffer[buf_id])
				return True


		# send out - warm water
		def generate_inet_upload(self, s, p):
 
				# Message warm water / counter = 1
#         self.prepare_tl_response(bytes.fromhex("03 10 29 fa 00 1f 00 1e 8b".replace(" ","")))
#         self.prepare_tl_response(bytes.fromhex("03 21 00 00 22 ff ff ff b9".replace(" ","")))
#         self.prepare_tl_response(bytes.fromhex("03 22 54 01 0c 32 02 22 23".replace(" ","")))
#         self.prepare_tl_response(bytes.fromhex("03 23 00 00 00 00 00 00 d9".replace(" ","")))
#         self.prepare_tl_response(bytes.fromhex("03 24 3a 0c 00 00 01 01 90".replace(" ","")))
#         self.prepare_tl_response(bytes.fromhex("03 25 00 00 00 00 00 00 d7".replace(" ","")))
#         self.prepare_tl_response(bytes.fromhex("03 26 00 00 00 00 00 00 d6".replace(" ","")))

				if self.app.upload_buffer:
						self.log.debug("heater_status to be generated")
						self.cmd_buf = self.app._get_status_buffer_for_writing()
						self.stop_async = True
						if self.app.upload_buffer > 0: self.app.upload_buffer -= 1

				if self.app.upload02_buffer:
						self.log.debug("aircon_status to be generated")
						self.cmd_buf = self.app._get_status_buffer1_for_writing()
						self.stop_async = True
						if self.app.upload02_buffer > 0: self.app.upload02_buffer -= 1

				if (self.cmd_buf == None) or (self.cmd_buf == {}):
						self.log.debug("cmd_buffer is empty")
						return
				self.d8_alive = True
				self.stop_async = True
				for i in self.cmd_buf:
						self.prepare_tl_response(i)
				self.updates_to_send = False
				if p.startswith("_"): return
				#self.log.debug(p)
 
		# check alive status
		def status_monitor(self):
			# Called every 9 seconds to check if device is alive
			self.app.status["alive"] = ["ON", True, False] 
			# Same approach for the raw PID 0xD8. This corresponds to a PID 0x18
			if self.d8_alive:
					self.app.status["alive"][0] = "ON"
			else:
					self.app.status["alive"][0] = "OFF"
			self.d8_alive = False
   
		# major ctrl loop for inetbox-communication
		async def _lin_loop(self):
			# Timing loop for status monitoring
			# Serial I/O now handled by data_received() callback
			while True:
				self.status_monitor()
				await asyncio.sleep(9.0)  # Check alive status every 9 seconds
		

   
		def _process_rx_buffer(self):
			
			while True:
				# Find sync 0x00 0x55
				sync_idx = self._rx_buf.find(b'\x00\x55')
			
				if sync_idx < 0:
					# No sync found - keep a trailing 0x00 in case sync spans chunks
					if self._rx_buf[-1:] == b'\x00':
						self._rx_buf[:] = b'\x00'
						#print(f"set \x00")
					else:
						self._rx_buf.clear()
						#print(f"clear")
					return
				
				if sync_idx > 0:
					# Sync not at start - discard leading garbage
					del self._rx_buf[:sync_idx]
					sync_idx = 0
				
				#print(f"sync_idx: {sync_idx}")
    
				# Now sync is at position 0
				# Need at least 3 bytes for raw PID
				if len(self._rx_buf) < 3:
					return  # Wait for more data
				
				raw_pid = self._rx_buf[2]
				
				# Determine required frame length
				frame_len = 3 if raw_pid in (0xD8, 0x7D) else 12
				#print(f"frame_len: {frame_len}")
				if len(self._rx_buf) < frame_len:
					return  # Wait for more data
				
				# Extract and process frame
				line = bytes(self._rx_buf[:frame_len])
				del self._rx_buf[:frame_len]
				self.log.lin_trace(f"Full frame received: {line.hex(' ')} ({len(line)} bytes)")
				
				self._process_frame(line, raw_pid)
				#if raw_pid in self.DISPLAY_STATUS_PIDS:
						#print(f"status-message found with {raw_pid:x}")
      
		def _process_frame(self, line, raw_pid):
			# self.log.trace(f"Processing frame: {line.hex(' ')}")
			if raw_pid == 0xd8:
				self.d8_alive = True
				self.app.status["alive"] = ["ON", True, False]

				#self.log.debug(f"in 1 < {line.hex(' ')}")
				s = False
				if not(self.app.upload_wait):
								s = (self.app.upload_buffer or self.app.upload02_buffer)
				if s:
					self.app.upload_wait = 4
					self.stop_async = True
					#self.log.debug("0x18 - update-requested")
					self._send_answer(bytearray.fromhex("ff ff ff ff ff ff ff ff 27".replace(" ","")))
					return
				else:
					self._send_answer(bytearray.fromhex("fe ff ff ff ff ff ff ff 28".replace(" ","")))
					if self.app.upload_wait:
						self.app.upload_wait -= 1
					return

			if raw_pid == 0x7d:
				if self.response_waiting():
					#self.log.debug(f"in 2 < {line.hex(' ')}")
					self._answer_tl_request()
				return

			#self.log.debug(f"in 3 < {line.hex(' ')}")

			buf_trans_id = bytes([0x00, 0x55, 0x3c, 0x03])
			if (line[:4]==buf_trans_id) and (line[4] in range(0x21, 0x27)):
				self.cpp_in_buffer[line[4] - 0x21] = line[5:-1]
				if (line[4] == 0x26):
					if (self.assemble_cpp_buffer()):
						self.prepare_tl_str_response("03 01 fb ff ff ff ff ff 00", "_send ackn-response for buffer delivery")
					return
				else:
					return
 
			cmd = line.hex(" ")
			entry = self.cmd_ctrl.get(cmd)
			if not entry is None:
				fn, msg, info = entry
				self.log.lin_trace(f"executing command: {info}")
				fn(self, msg, info)
			
			return

		cmd_ctrl = {
			"00 55 3c 7f 06 b2 00 17 46 00 1f 4b": [prepare_tl_str_response, "03 06 f2 17 46 00 1f 00 87", "_B2 - response request"],
			"00 55 03 aa 0a ff ff ff ff ff ff 48": [no_answer, "", "_NAD 03 response - ack"],
			"00 55 3c 03 06 b2 20 17 46 00 1f a7": [prepare_tl_str_response, "03 06 f2 17 46 00 1f 00 87", "B2 - identifier for NAD 03"],
			"00 55 3c 03 06 b2 22 17 46 00 1f a5": [prepare_tl_str_response, "03 06 f2 17 46 00 1f 00 87", "B2 - initializer for NAD 03   -----------------> start registration"],
			"00 55 3c 7f 06 b0 17 46 00 1f 03 4a": [prepare_tl_str_response, "03 01 f0 ff ff ff ff ff 0b", "B0 - init finalized - send ackn ---------------> registration finalized"],
			"00 55 3c 03 05 b9 00 1f 00 00 ff 1f": [prepare_tl_str_response, "03 02 f9 00 ff ff ff ff 01", "_Heartbeat for NAD 03 - send response"],
			"00 55 3c 03 10 29 bb 00 1f 00 1e ca": [no_answer, "", "_Frame 1 of buffer-transfer (6 frames) from CPplus"],
			"00 55 3c 03 10 0b ba 00 1f 00 1e e9": [generate_inet_upload, "", "BA-request: upload started"],
			"00 55 03 aa 0a ff ff ff ff ff ff 48": [no_answer, "", "_ackn from CPplus"],
		}