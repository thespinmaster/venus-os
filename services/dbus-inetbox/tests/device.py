#!/usr/bin/env python3

import os
import pty
import asyncio
import json
import fcntl

def read_recording(filename):
    """Read and parse a recording file (JSONL format)."""
    chunks = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            chunk = json.loads(line)
            chunks.append((
                chunk['timestamp'],
                chunk['direction'],
                bytes.fromhex(chunk['data'])
            ))
    
    return chunks


class VirtualSerialDevice:
    def __init__(self, recording_file, respect_timing=True, speed_multiplier=1.0):
        self.master_fd, self.slave_fd = pty.openpty()
        self.slave_name = os.ttyname(self.slave_fd)
        
        self.symlink_path = "/tmp/lin_sim"
        if os.path.islink(self.symlink_path) or os.path.exists(self.symlink_path):
            os.unlink(self.symlink_path)
        os.symlink(self.slave_name, self.symlink_path)
        
        self.chunks = read_recording(recording_file)
        self.respect_timing = respect_timing
        self.speed_multiplier = speed_multiplier
        self._rx_buffer = bytearray()
        
        # Set master fd to non-blocking
        flags = fcntl.fcntl(self.master_fd, fcntl.F_GETFL)
        fcntl.fcntl(self.master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)
        
    async def replay(self):
        print(f"[SIM] Virtual serial device ready:")
        print(f"[SIM]   -> connect to {self.slave_name}")
        print(
            f"[SIM] Starting replay "
            f"(respect_timing={self.respect_timing}, "
            f"speed={self.speed_multiplier}x)"
        )
        print()
        
        
        loop = asyncio.get_running_loop()
        await asyncio.sleep(3)
        
        start_time = loop.time()
    
        frame_count = 0
        
        for i, (timestamp, direction, data) in enumerate(self.chunks):
            if self.respect_timing:
                target_time = start_time + (timestamp / self.speed_multiplier)
                now = loop.time()
                if target_time > now:
                    await asyncio.sleep(target_time - now)

            if direction == "in":
                # Device->App: accumulate bytes and split into frames
                self._rx_buffer.extend(data)

                while True:
                    # Look for sync pattern 00 55
                    sync_idx = self._rx_buffer.find(b'\x00\x55')
                    if sync_idx < 0:
                        # Keep last 0x00 in case sync starts there
                        self._rx_buffer = self._rx_buffer[-1:] if self._rx_buffer[-1:] == b'\x00' else bytearray()
                        break

                    # Need at least 3 bytes for raw PID
                    if len(self._rx_buffer) < sync_idx + 3:
                        break

                    raw_pid = self._rx_buffer[sync_idx + 2]
                    frame_len = 3 if raw_pid in (0xD8, 0x7D) else 12

                    if len(self._rx_buffer) < sync_idx + frame_len:
                        break

                    frame = bytes(self._rx_buffer[sync_idx:sync_idx + frame_len])
                    del self._rx_buffer[:sync_idx + frame_len]

                    frame_count += 1
                    print(f"[SIM→APP] Frame {frame_count}: {frame.hex(' ')}")

                    # Send frame byte-by-byte
                    for byte in frame:
                        os.write(self.master_fd, bytes([byte]))
                        await asyncio.sleep(0.0011)

                    await asyncio.sleep(0.002)
                    
            elif direction == "out":
                # App->Device: Read expected response from app
                print(f"[APP→SIM] Expected response: {data.hex(' ')}")
                
                # Try to read actual response from app
                await asyncio.sleep(0.02)  # Give app time to respond
                
                # Check if app sent the expected data
                try:
                    actual = os.read(self.master_fd, len(data))
                    if actual == data:
                        print(f"[APP→SIM] ✓ Response matches")
                    else:
                        print(f"[APP→SIM] ✗ Response mismatch:")
                        print(f"           Expected: {data.hex(' ')}")
                        print(f"           Got:      {actual.hex(' ')}")
                except (BlockingIOError, OSError):
                    print(f"[APP→SIM] ✗ No response received")

            if i % 10 == 0 and direction == "in":
                print(f"[SIM] Progress: chunk {i+1}/{len(self.chunks)}, {frame_count} frames sent")

        print(f"\n[SIM] Replay complete - {frame_count} frames sent")
 
    def close(self):
        try:
            os.close(self.master_fd)
            os.close(self.slave_fd)
        except:
            pass

async def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Replay a recorded LIN session.")
    parser.add_argument("recording_file", help="Path to recording file (JSONL)")
    parser.add_argument(
        "--ignore_timing",
        action="store_true",
        help="Ignore recorded timing (replay as fast as possible)",
    )
    parser.add_argument(
        "--speed",
        type=float,
        default=1.0,
        help="Speed multiplier for timing (default: 1.0)",
    )
    args = parser.parse_args()

    recording_file = args.recording_file
    respect_timing = not args.ignore_timing
    speed_multiplier = args.speed
    
    device = VirtualSerialDevice(recording_file, respect_timing, speed_multiplier)
    
    try:
        await device.replay()
    finally:
        device.close()


if __name__ == "__main__":
    asyncio.run(main())
