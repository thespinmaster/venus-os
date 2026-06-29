#!/usr/bin/python3 -u

import json
import logging
import os
import signal
import subprocess
import sys
import threading
import uuid
from collections import deque
from dataclasses import dataclass, field
from typing import List, Optional

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib  # type: ignore

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
EXT_DIR = os.path.join(THIS_DIR, "ext")

if EXT_DIR not in sys.path:
    sys.path.insert(0, EXT_DIR)

from vedbus import VeDbusService  # type: ignore

SERVICE_NAME = "com.victronenergy.opkgmanager"
VERSION = "2.1.0"
BRIDGE_ROOT = "/data/opkg-manager/opkg-bridge"

CHUNK_MAX_SIZE = 65536
CHUNK_DEFAULT_SIZE = 32768
CHUNK_RESULT_RESET_DELAY_MS = 250

# Named data sources served via the /Chunk/ D-Bus API.
# Keys are the names the UI passes in /Chunk/Request/Name.
CHUNK_SOURCE_REGISTRY = {
    "packages": "/tmp/opkg-manager/packages.json",
    "feeds": "/tmp/opkg-manager/feeds.json",
}

COMMAND_REGISTRY = {
    "test": {
        "default": {
            "helper_name": "test",
            "helper_path": f"{BRIDGE_ROOT}/test",
        },
        "actions": {
            "test1": {},
            "test2": {},
            "test3": {},
            "test-loop": {},
            "hello-world": {},
            "test-error-formatting": {},

        },
    },
    "packages": {
        "default": {
            "helper_name": "packages_helper",
            "helper_path": f"{BRIDGE_ROOT}/packages_helper",
        },
				"actions": {
						"update": {}
				}
		},
    "feed": {
        "default": {
            "helper_name": "feed",
            "helper_path": f"{BRIDGE_ROOT}/feed",
        },
        "actions": {
            "add": {},
            "edit": {},
            "remove": {},
            "set": {},
            "type": {},
        },
    },
    "package": {
        "default": {
            "helper_name": "package",
            "helper_path": f"{BRIDGE_ROOT}/package",
        },
        "actions": {
            "install": {},
            "remove": {},
            "upgrade": {},
        },
    },
    "device": {
        "default": {
            "helper_name": "device",
            "helper_path": f"{BRIDGE_ROOT}/device",
        },
        "actions": {
            "detect": {},
            "apply": {},
            "remove": {},
        },
    }
}


class LevelFilter(logging.Filter):
    def __init__(self, passlevels, reject):
        self.passlevels = passlevels
        self.reject = reject

    def filter(self, record):
        if self.reject:
            return (record.levelno not in self.passlevels)
        else:
            return (record.levelno in self.passlevels)

# Leave the name set to None to get the root logger. For some reason specifying 'root' has a
# different effect: there will be two root loggers, both with their own handlers...
def setup_logging(debug=False, name=None):
    formatter = logging.Formatter(fmt='%(asctime)s %(levelname)s:%(module)s:%(message)s', datefmt='%Y-%m-%d %H:%M:%S')

    # Make info and debug stream to stdout and the rest to stderr
    h1 = logging.StreamHandler(sys.stdout)
    h1.addFilter(LevelFilter([logging.INFO, logging.DEBUG], False))
    h1.setFormatter(formatter)

    h2 = logging.StreamHandler(sys.stderr)
    h2.addFilter(LevelFilter([logging.INFO, logging.DEBUG], True))
    h2.setFormatter(formatter)

    logger = logging.getLogger(name)
    for handler in list(logger.handlers):
        logger.removeHandler(handler)
    logger.addHandler(h1)
    logger.addHandler(h2)
    logger.propagate = False

    # Set the loglevel and show it
    logger.setLevel(level=(logging.DEBUG if debug else logging.INFO))
    logLevel = {0: 'NOTSET', 10: 'DEBUG', 20: 'INFO', 30: 'WARNING', 40: 'ERROR'}
    logger.info('Loglevel set to ' + logLevel[logger.getEffectiveLevel()])

    return logger


log = setup_logging(debug=(os.getenv("OPKG_MANAGER_LOG_LEVEL", "INFO").upper() == "DEBUG"), name=None)


def _log_unhandled_exception(exc_type, exc_value, exc_traceback):
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return
    log.critical("Unhandled exception", exc_info=(exc_type, exc_value, exc_traceback))


def _log_thread_exception(args):
    _log_unhandled_exception(args.exc_type, args.exc_value, args.exc_traceback)


sys.excepthook = _log_unhandled_exception
threading.excepthook = _log_thread_exception

@dataclass
class CommandState:
    request_id: str
    helper_name: str
    helper_path: str
    args: List[str]
    operation_name: str
    process: subprocess.Popen
    stdout_done: bool = False
    stderr_done: bool = False
    wait_done: bool = False
    finish_scheduled: bool = False
    cancelled: bool = False
    output_queue: deque = field(default_factory=deque)
    _drain_pending: bool = False
    drain_source_id: int = 0
    exit_code: int = 1
    exit_status: int = 1
    stderr_lines: List[str] = field(default_factory=list)


class OpkgManagerService:
    def __init__(self):
        DBusGMainLoop(set_as_default=True)
        log.info("Initializing service %s version=%s", SERVICE_NAME, VERSION)

        self._lock = threading.RLock()
        self._active: Optional[CommandState] = None

        self._dbusservice = VeDbusService(SERVICE_NAME, bus=dbus.SystemBus(), register=False)
        self._dbusservice.add_mandatory_paths(
            processname=__file__,
            processversion=VERSION,
            connection="opkg-manager",
            deviceinstance=0,
            productid=0,
            productname="opkg-manager",
            firmwareversion=1,
            hardwareversion=1,
            connected=1,
        )

        self._dbusservice.add_path("/ServiceName", "opkg-manager")

        self._dbusservice.add_path("/Request/ArgsJson", "[]", writeable=True, valuetype=dbus.String)
        self._dbusservice.add_path(
            "/Request/Start",
            dbus.UInt32(0),
            writeable=True,
            valuetype=dbus.UInt32,
            onchangecallback=self._on_start_requested,
        )
        self._dbusservice.add_path(
            "/Request/Cancel",
            dbus.UInt32(0),
            writeable=True,
            valuetype=dbus.UInt32,
            onchangecallback=self._on_cancel_requested,
        )


        self._dbusservice.add_path("/State/RequestId", "", valuetype=dbus.String)
        self._dbusservice.add_path("/State/Status", dbus.UInt16(0), valuetype=dbus.UInt16)

        self._dbusservice.add_path("/Event/StdoutLine", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Event/StdoutSeq", dbus.UInt32(0), valuetype=dbus.UInt32)
        self._dbusservice.add_path("/Event/StderrLine", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Event/StderrSeq", dbus.UInt32(0), valuetype=dbus.UInt32)
        self._dbusservice.add_path("/Event/FinishedSeq", dbus.UInt32(0), valuetype=dbus.UInt32)

        self._dbusservice.add_path("/Result/ExitCode", 0, valuetype=dbus.Int32)
        self._dbusservice.add_path("/Result/ExitStatus", dbus.UInt16(0), valuetype=dbus.UInt16)
        self._dbusservice.add_path("/Result/Error", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Result/Json", "", valuetype=dbus.String, writeable=True)

        self._dbusservice.add_path("/Chunk/Request/Name", "", writeable=True, valuetype=dbus.String)
        self._dbusservice.add_path("/Chunk/Request/Offset", dbus.UInt32(0), writeable=True, valuetype=dbus.UInt32)
        self._dbusservice.add_path("/Chunk/Request/MaxSize", dbus.UInt32(CHUNK_DEFAULT_SIZE), writeable=True, valuetype=dbus.UInt32)
        self._dbusservice.add_path(
            "/Chunk/Request/Seq",
            dbus.UInt32(0),
            writeable=True,
            valuetype=dbus.UInt32,
            onchangecallback=self._on_chunk_requested,
        )
        self._dbusservice.add_path("/Chunk/Result/Seq", dbus.UInt32(0), valuetype=dbus.UInt32)
        self._dbusservice.add_path("/Chunk/Result/Data", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Chunk/Result/EndOfData", dbus.UInt16(0), valuetype=dbus.UInt16)
        self._dbusservice.add_path("/Chunk/Result/SourceVersion", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Chunk/Result/Error", "", valuetype=dbus.String)

        self._dbusservice.register()
        log.info("D-Bus service registered: %s", SERVICE_NAME)
        self._loop = GLib.MainLoop()

    def run(self):
        log.info("Main loop started")
        self._loop.run()

    def _on_start_requested(self, _path, _value):
        log.info("Start requested")
        GLib.idle_add(self._start_command)
        return True

    def _on_cancel_requested(self, _path, _value):
        log.info("Cancel requested")
        # Set cancelled synchronously here (on the main thread) so that any
        # _emit_stdout/_emit_stderr idle callbacks already in the GLib queue
        # will see the flag and skip emission when they run.
        with self._lock:
            state = self._active
        if state:
            state.cancelled = True
        GLib.idle_add(self._cancel_command)
        return True

    def _start_command(self):
        with self._lock:
            if self._active and self._active.process.poll() is None:
                log.warning("Rejecting start: command already running")
                self._set_error("Command already running")
                return False

        args_json = str(self._dbusservice["/Request/ArgsJson"] or "[]")

        try:
            args = json.loads(args_json)
            if not isinstance(args, list):
                raise ValueError("ArgsJson must contain a JSON array")
            args = [str(arg) for arg in args]
            log.info("Parsed request args: %s", args)
        except Exception as err:
            self._finish_start_error(f"Invalid args json: {err}")
            return False

        try:
            helper_name, helper_path, helper_args, operation_name = self._resolve_command(args)
            log.info(
                "Resolved command operation=%s helper=%s path=%s args=%s",
                operation_name,
                helper_name,
                helper_path,
                helper_args,
            )
        except ValueError as err:
            self._finish_start_error(str(err))
            return False

        self._reset_result_state()

        try:
            process = subprocess.Popen(
                [helper_path] + helper_args,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True,
                start_new_session=True,
            )
            log.info("Started process pid=%s operation=%s", process.pid, operation_name)
        except Exception as err:
            self._finish_start_error(f"Failed to start process: {err}")
            return False

        state = CommandState(
            request_id=str(uuid.uuid4()),
            helper_name=helper_name,
            helper_path=helper_path,
            args=helper_args,
            operation_name=operation_name,
            process=process,
            stderr_done=True,
        )

        with self._lock:
            self._active = state

        self._dbusservice["/State/Status"] = dbus.UInt16(1) # running 1
				#self._dbusservice["/State/RequestId"] = state.request_id

        threading.Thread(target=self._stream_output, args=(state,), daemon=True).start()
        threading.Thread(target=self._wait_for_process, args=(state,), daemon=True).start()
        return False

    def _cancel_command(self):
        with self._lock:
            state = self._active

        if not state:
            log.info("Cancel requested with no active process")
            return False

        state.cancelled = True
        self._cancel_pending_drain(state)

        if state.process.poll() is not None:
            log.info("Cancel requested but process already exited; suppressing remaining output")
            return False
        self._dbusservice["/State/Status"] = dbus.UInt16(3) # 1 running 2 cancelling
        log.info("Stopping process pid=%s operation=%s", state.process.pid, state.operation_name)

        try:
            os.killpg(state.process.pid, signal.SIGTERM)
        except Exception:
            try:
                state.process.terminate()
            except Exception:
                pass

        return False

    def _cancel_pending_drain(self, state: CommandState):
        with self._lock:
            drain_source_id = state.drain_source_id
            state.drain_source_id = 0
            state.output_queue.clear()
            state._drain_pending = False

        if drain_source_id:
            try:
                GLib.source_remove(drain_source_id)
            except Exception:
                pass

    def _resolve_command(self, args: List[str]):
        if len(args) < 2:
            raise ValueError("Expected args: <family> <action> [args...]")

        family = args[0].strip()
        action = args[1].strip()
        if not family or not action:
            raise ValueError("Family and action are required")

        family_spec = COMMAND_REGISTRY.get(family)
        if not family_spec:
            raise ValueError(f"Unsupported command family: {family}")

        action_spec = family_spec["actions"].get(action)
        if action_spec is None:
            raise ValueError(f"Unsupported {family} action: {action}")

        helper_name = family_spec["default"]["helper_name"]
        helper_path = action_spec.get("helper_path") or family_spec["default"]["helper_path"]
        prefix_args = action_spec.get("prefix_args", [])

        if not os.path.isfile(helper_path):
            raise ValueError(f"Helper not found: {helper_path}")
        if not os.access(helper_path, os.X_OK):
            raise ValueError(f"Helper not executable: {helper_path}")

        helper_args = [*prefix_args, action, *args[2:]]
        operation_name = f"{family} {action}"
        return helper_name, helper_path, helper_args, operation_name

    def _stream_output(self, state: CommandState):
        stream = state.process.stdout
        if stream is None:
            self._mark_stream_done(state, True)
            return

        try:
            for raw_line in stream:
                if state.cancelled:
                    break
                line = raw_line.rstrip("\r\n")
                state.stderr_lines.append(line)
                state.output_queue.append(line)
                with self._lock:
                    if not state._drain_pending and not state.cancelled:
                        state._drain_pending = True
                        state.drain_source_id = GLib.idle_add(self._drain_output, state)
        finally:
            self._mark_stream_done(state, True)

    def _drain_output(self, state: CommandState):
        with self._lock:
            state.drain_source_id = 0
            if state.cancelled:
                state.output_queue.clear()
                state._drain_pending = False
                return False

        # Process a small batch so the main loop stays responsive to D-Bus events
        # (e.g. a cancel request arriving while output is still streaming).
        batch = 10
        for _ in range(batch):
            if state.cancelled:
                break
            if state.output_queue:
                line = state.output_queue.popleft()
                self._dbusservice["/Event/StdoutLine"] = line
                self._dbusservice["/Event/StdoutSeq"] = dbus.UInt32(int(self._dbusservice["/Event/StdoutSeq"]) + 1)
            else:
                break

        with self._lock:
            if state.cancelled:
                state.output_queue.clear()
                state._drain_pending = False
            elif state.output_queue:
                # More items remain — reschedule and yield to the main loop
                state.drain_source_id = GLib.idle_add(self._drain_output, state)
            else:
                state._drain_pending = False
        return False

    def _mark_stream_done(self, state: CommandState, is_stdout: bool):
        with self._lock:
            if self._active is not state:
                return
            if is_stdout:
                state.stdout_done = True
            else:
                state.stderr_done = True
            self._maybe_finish_command_locked(state)

    def _wait_for_process(self, state: CommandState):
        exit_code = 1
        exit_status = 1
        try:
            rc = state.process.wait()
            exit_code = int(rc)
            exit_status = 0
            log.info("Process exited pid=%s operation=%s code=%s", state.process.pid, state.operation_name, exit_code)
        except Exception:
            log.exception("Error while waiting for process pid=%s operation=%s", state.process.pid, state.operation_name)
            pass

        with self._lock:
            if self._active is not state:
                return
            state.exit_code = exit_code
            state.exit_status = exit_status
            state.wait_done = True
            self._maybe_finish_command_locked(state)

    def _maybe_finish_command_locked(self, state: CommandState):
        if self._active is not state or state.finish_scheduled:
            return

        if not (state.wait_done and state.stdout_done and state.stderr_done):
            return

        state.finish_scheduled = True
        GLib.idle_add(self._finish_command, state, state.exit_code, state.exit_status)

    def _finish_command(self, state: Optional[CommandState], exit_code: int, exit_status: int):
        with self._lock:
            active = self._active
            if state is not None and active is not state:
                return False
            self._active = None

        self._dbusservice["/State/Status"] = dbus.UInt16(0)
        self._dbusservice["/Result/ExitCode"] = dbus.Int32(exit_code)
        self._dbusservice["/Result/ExitStatus"] = dbus.UInt16(exit_status)

        if state and state.cancelled:
            self._dbusservice["/Result/Error"] = ""
        elif exit_code != 0 and state and state.stderr_lines and not self._dbusservice["/Result/Error"]:
            self._dbusservice["/Result/Error"] = state.stderr_lines[-1]

        log.info(
            "Finished request_id=%s exit_code=%s exit_status=%s error=%s",
            # state.operation_name if state else self._dbusservice["/State/OperationName"],
            state.request_id if state else 0,
            exit_code,
            exit_status,
            self._dbusservice["/Result/Error"],
        )

        self._dbusservice["/Event/FinishedSeq"] = dbus.UInt32(int(self._dbusservice["/Event/FinishedSeq"]) + 1)
        return False

    def _on_chunk_requested(self, _path, _value):
        log.debug("Chunk requested")
        GLib.idle_add(self._serve_chunk)
        return True

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

    def _serve_chunk(self):
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

    def _set_error(self, message: str):
        self._dbusservice["/Result/Error"] = message
        log.error("Result error set: %s", message)

    def _finish_start_error(self, message: str):
        self._reset_result_state()
        self._set_error(message)
        self._finish_command(None, 1, 1)

    def _reset_result_state(self):
        self._dbusservice["/Result/ExitCode"] = dbus.Int32(0)
        self._dbusservice["/Result/ExitStatus"] = dbus.UInt16(0)
        self._dbusservice["/Result/Error"] = ""

def main():
    log.info("Starting opkg-manager service process")
    service = OpkgManagerService()
    service.run()


if __name__ == "__main__":
    main()