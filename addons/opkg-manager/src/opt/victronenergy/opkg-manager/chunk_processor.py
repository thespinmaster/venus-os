import logging
import os

import dbus
from gi.repository import GLib  # type: ignore

log = logging.getLogger(__name__)

CHUNK_MAX_SIZE = 65536
CHUNK_DEFAULT_SIZE = 32768
CHUNK_RESULT_RESET_DELAY_MS = 250

# Named data sources served via the /Chunk/ D-Bus API.
# Keys are the names the UI passes in /Chunk/Request/Name.
CHUNK_SOURCE_REGISTRY = {
		"packages": "/tmp/opkg-manager/packages.json",
		"feeds": "/tmp/opkg-manager/feeds.json",
}


class ChunkProcessor:
		"""Serves named file data in chunks over the /Chunk D-Bus paths."""

		def __init__(self, dbusservice):
				self._dbusservice = dbusservice

		def on_chunk_requested(self, _path, _value):
				log.debug("Chunk requested")
				GLib.idle_add(self.serve_chunk)
				return True

		def serve_chunk(self):
				name = str(self._dbusservice["/Chunk/Request/Name"] or "").strip()
				offset = int(self._dbusservice["/Chunk/Request/Offset"] or 0)
				max_size = int(self._dbusservice["/Chunk/Request/MaxSize"] or CHUNK_DEFAULT_SIZE)
				req_seq = int(self._dbusservice["/Chunk/Request/Seq"] or 0)
				log.debug("Serving chunk name=%s offset=%s max_size=%s seq=%s", name, offset, max_size, req_seq)

				self._dbusservice["/Chunk/Result/Data"] = ""
				self._dbusservice["/Chunk/Result/EndOfData"] = dbus.UInt16(0)
				self._dbusservice["/Chunk/Result/SourceVersion"] = ""
				self._dbusservice["/Chunk/Result/Error"] = ""

				if not name:
						self._dbusservice["/Chunk/Result/Error"] = "Name is required"
						self._dbusservice["/Chunk/Result/Seq"] = dbus.UInt32(req_seq)
						log.warning("Chunk request rejected: missing name")
						return False

				file_path = CHUNK_SOURCE_REGISTRY.get(name)
				if file_path is None:
						self._dbusservice["/Chunk/Result/Error"] = f"Unknown source: {name}"
						self._dbusservice["/Chunk/Result/Seq"] = dbus.UInt32(req_seq)
						log.warning("Chunk request rejected: unknown source name=%s", name)
						return False

				if not os.path.isfile(file_path):
						self._dbusservice["/Chunk/Result/Error"] = f"Source not available: {name}"
						self._dbusservice["/Chunk/Result/Seq"] = dbus.UInt32(req_seq)
						log.warning("Chunk source missing name=%s path=%s", name, file_path)
						return False

				should_reset_result = False

				try:
						max_size = max(1, min(max_size, CHUNK_MAX_SIZE))
						mtime = str(int(os.path.getmtime(file_path) * 1000))

						with open(file_path, "rb") as fh:
								fh.seek(offset)
								chunk = fh.read(max_size)
								end_pos = fh.tell()

						file_size = os.path.getsize(file_path)
						end_of_data = 1 if end_pos >= file_size else 0

						self._dbusservice["/Chunk/Result/Data"] = chunk.decode("utf-8")
						self._dbusservice["/Chunk/Result/EndOfData"] = dbus.UInt16(end_of_data)
						self._dbusservice["/Chunk/Result/SourceVersion"] = mtime
						log.debug("Chunk served name=%s bytes=%s end_of_data=%s", name, len(chunk), end_of_data)
						should_reset_result = end_of_data == 1
				except Exception as err:
						self._dbusservice["/Chunk/Result/Error"] = f"Read error: {err}"
						log.exception("Chunk read error name=%s path=%s", name, file_path)

				self._dbusservice["/Chunk/Result/Seq"] = dbus.UInt32(req_seq)
				if should_reset_result:
						GLib.timeout_add(CHUNK_RESULT_RESET_DELAY_MS, self._reset_chunk_result_if_current, req_seq)
				return False

		def _reset_chunk_result_if_current(self, req_seq: int):
				current_seq = int(self._dbusservice["/Chunk/Result/Seq"] or 0)
				if current_seq != req_seq:
						return False

				if int(self._dbusservice["/Chunk/Result/EndOfData"] or 0) != 1:
						return False

				self._dbusservice["/Chunk/Result/Data"] = ""
				self._dbusservice["/Chunk/Result/EndOfData"] = dbus.UInt16(0)
				self._dbusservice["/Chunk/Result/Error"] = ""
				log.debug("Chunk result reset for seq=%s", req_seq)
				return False
