#!/usr/bin/env python3

import json
import os
import signal
import subprocess
import sys
import threading
import uuid
from dataclasses import dataclass, field
from typing import List, Optional

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib # type: ignore

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
EXT_DIR = os.path.join(THIS_DIR, "ext")

if EXT_DIR not in sys.path:
    sys.path.insert(0, EXT_DIR)

if THIS_DIR not in sys.path:
    sys.path.insert(0, THIS_DIR)

from vedbus import VeDbusService # type: ignore
from opkg_helpers import QML_FILE_SERVER_DIR

SERVICE_NAME = "com.victronenergy.opkgmanager"
VERSION = "2.0.0"

LIB_FOLDER_PATH=f"{THIS_DIR}/libs"

HTTP_PORT = 8888
HTTP_HOST = "127.0.0.1"

# Central command registry: one place to add/update command families and actions.
COMMAND_REGISTRY = {
    "test": {
        "default": {
            "helper_name": "test",
            "helper_path": f"{LIB_FOLDER_PATH}/test",
        },
        "actions": {
            "test1": {},
            "test2": {},
            "test3": {},
            "hello-world": {},
        },
    },
    "feed": {
        "default": {
            "helper_name": "feed",
            "helper_path": f"{LIB_FOLDER_PATH}/feed",
        },
        "actions": {
            "list": {
                "helper_path": sys.executable,
                "prefix_args": [os.path.join(THIS_DIR, "opkg_helpers.py"), "package"],
                "source_files": "feeds.json"
            },
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
            "helper_path": f"{LIB_FOLDER_PATH}/package",
        },
        "actions": {
            "list": {
                "helper_path": sys.executable,
                "prefix_args": [os.path.join(THIS_DIR, "opkg_helpers.py"), "package"],
                "source_files": "packages.json"
            },
            "install": {},
            "remove": {},
            "upgrade": {},
        },
    },
    "device": {
        "default": {
            "helper_name": "device",
            "helper_path": f"{LIB_FOLDER_PATH}/device",
        },
        "actions": {
            "detect": {},
            "apply": {},
            "remove": {},
        },
    },
}

@dataclass
class CommandState:
    request_id: str
    helper_name: str
    helper_path: str
    args: List[str]
    operation_name: str
    source_files: str
    process: subprocess.Popen
    stdout_done: bool = False
    stderr_done: bool = False
    stderr_lines: List[str] = field(default_factory=list)

class OpkgManagerService:
        
    @dbus.service.method(dbus_interface='com.example.Sample',
                         in_signature='v', out_signature='s')
    def GetJsonResult(self, value):
        return ""

    def __init__(self):
        DBusGMainLoop(set_as_default=True)

        self._lock = threading.RLock()
        self._active: Optional[CommandState] = None
        self._http_server_process: Optional[subprocess.Popen] = None
        self._allow_internal_http_source_write = False

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

        self._dbusservice.add_path("/State/Running", dbus.UInt16(0), valuetype=dbus.UInt16)
        self._dbusservice.add_path("/State/Stopping", dbus.UInt16(0), valuetype=dbus.UInt16)
        self._dbusservice.add_path("/State/OperationName", "", valuetype=dbus.String)
        self._dbusservice.add_path("/State/RequestId", "", valuetype=dbus.String)

        self._dbusservice.add_path("/Event/StdoutLine", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Event/StdoutSeq", dbus.UInt32(0), valuetype=dbus.UInt32)
        self._dbusservice.add_path("/Event/StderrLine", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Event/StderrSeq", dbus.UInt32(0), valuetype=dbus.UInt32)
        self._dbusservice.add_path("/Event/FinishedSeq", dbus.UInt32(0), valuetype=dbus.UInt32)

        self._dbusservice.add_path("/Result/ExitCode", 0, valuetype=dbus.Int32)
        self._dbusservice.add_path("/Result/ExitStatus", dbus.UInt16(0), valuetype=dbus.UInt16)
        self._dbusservice.add_path("/Result/Error", "", valuetype=dbus.String)
 
        self._dbusservice.add_path(
            "/HttpServer/Source",
            "",
            writeable=True,
            valuetype=dbus.String,
            onchangecallback=self._on_http_server_source_requested,
        )

        self._dbusservice.register()
        self._loop = GLib.MainLoop()

    def run(self):
        try:
            self._loop.run()
        finally:
            self._stop_http_server()

    def _on_start_requested(self, _path, _value):
        GLib.idle_add(self._start_command)
        return True

    def _on_cancel_requested(self, _path, _value):
        GLib.idle_add(self._cancel_command)
        return True

    def _on_http_server_source_requested(self, _path, value):
        requested = str(value or "")
        if self._allow_internal_http_source_write:
            return True

        if requested == "":
            GLib.idle_add(self._handle_http_source_cleared)
            return True

        # Reject external attempts to set non-empty sources.
        return False

    def _handle_http_source_cleared(self):
        self._stop_http_server()
        return False

    def _set_http_source_internal(self, source: str):
        self._allow_internal_http_source_write = True
        try:
            self._dbusservice["/HttpServer/Source"] = source
        finally:
            self._allow_internal_http_source_write = False
        return False

    def _is_http_server_running(self) -> bool:
        """Check if HTTP server process is running."""
        if self._http_server_process is None:
            return False
        return self._http_server_process.poll() is None

    def _start_http_server(self) -> bool:
        """Start HTTP server via subprocess."""
        if self._is_http_server_running():
            return True

        try:
            os.makedirs(QML_FILE_SERVER_DIR, exist_ok=True)
            self._http_server_process = subprocess.Popen(
                [
                    "python3", "-m", "http.server",
                    str(HTTP_PORT),
                    "--bind", HTTP_HOST,
                    "--directory", QML_FILE_SERVER_DIR,
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return True
        except Exception as e:
            print(f"Failed to start HTTP server: {e}")
            self._http_server_process = None
            return False

    def _stop_http_server(self) -> None:
        """Stop HTTP server process."""
        if self._http_server_process is not None:
            try:
                self._http_server_process.terminate()
                self._http_server_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._http_server_process.kill()
            except Exception as e:
                print(f"Error stopping HTTP server: {e}")
            finally:
                self._http_server_process = None

    def _start_command(self):
        with self._lock:
            if self._active and self._active.process.poll() is None:
                self._set_error("Command already running")
                return False

        args_json = str(self._dbusservice["/Request/ArgsJson"] or "[]")

        try:
            args = json.loads(args_json)
            if not isinstance(args, list):
                raise ValueError("ArgsJson must contain a JSON array")
            args = [str(arg) for arg in args]
        except Exception as err:
            self._set_error(f"Invalid args json: {err}")
            return False

        try:
            helper_name, helper_path, helper_args, source_files, operation_name = self._resolve_command(args)
        except ValueError as err:
            self._set_error(str(err))
            return False

        self._reset_result_state(operation_name)

        try:
            process = subprocess.Popen(
                [helper_path] + helper_args,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True,
                start_new_session=True,
            )
 
        except Exception as err:
            self._set_error(f"Failed to start process: {err}")
            self._finish_command(None, 1, 1)
            return False

        state = CommandState(
            request_id=str(uuid.uuid4()),
            helper_name=helper_name,
            helper_path=helper_path,
            args=helper_args,
            source_files=source_files,
            operation_name=operation_name,
            process=process,
        )

        with self._lock:
            self._active = state

        self._dbusservice["/State/Running"] = dbus.UInt16(1)
        self._dbusservice["/State/Stopping"] = dbus.UInt16(0)
        self._dbusservice["/State/OperationName"] = operation_name
        self._dbusservice["/State/RequestId"] = state.request_id
        

        threading.Thread(target=self._stream_output, args=(state, True), daemon=True).start()
        threading.Thread(target=self._stream_output, args=(state, False), daemon=True).start()
        threading.Thread(target=self._wait_for_process, args=(state,), daemon=True).start()
        return False

    def _cancel_command(self):
        with self._lock:
            state = self._active

        if not state or state.process.poll() is not None:
            self._dbusservice["/State/Stopping"] = dbus.UInt16(0)
            return False

        self._dbusservice["/State/Stopping"] = dbus.UInt16(1)

        try:
            os.killpg(state.process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        except Exception as err:
            self._set_error(f"Cancel failed: {err}")

        return False

    def _stream_output(self, state: CommandState, is_stdout: bool):
        stream = state.process.stdout if is_stdout else state.process.stderr

        if stream is None:
            self._set_stream_done(state, is_stdout)
            return

        try:
            for raw_line in iter(stream.readline, ""):
                line = raw_line.rstrip("\r\n")
                if is_stdout:
                    GLib.idle_add(self._emit_stdout_line, line)
                else:
                    state.stderr_lines.append(line)
                    GLib.idle_add(self._emit_stderr_line, line)
        except Exception as err:
            GLib.idle_add(self._emit_stderr_line, f"Stream read failed: {err}")
        finally:
            try:
                stream.close()
            except Exception:
                pass
            self._set_stream_done(state, is_stdout)

    def _wait_for_process(self, state: CommandState):
        exit_status = 0
        try:
            state.process.wait()
        except Exception as err:
            self._set_error(f"Wait failed: {err}")
            exit_status = 1

        self._wait_for_streams_done(state)

        return_code = state.process.poll()
        if return_code is None:
            return_code = 1
            exit_status = 1
        elif return_code < 0:
            exit_status = 1
        elif state.source_files:
            GLib.idle_add(self._publish_http_source, str(state.source_files))

        GLib.idle_add(self._finish_command, state, int(return_code), int(exit_status))

    def _finish_command(self, state: Optional[CommandState], exit_code: int, exit_status: int):
        active_request = ""

        with self._lock:
            if self._active is state:
                active_request = state.request_id if state else ""
                self._active = None

        self._dbusservice["/Result/ExitCode"] = int(exit_code)
        self._dbusservice["/Result/ExitStatus"] = dbus.UInt16(exit_status)
        self._dbusservice["/State/Running"] = dbus.UInt16(0)
        self._dbusservice["/State/Stopping"] = dbus.UInt16(0)
        self._dbusservice["/State/OperationName"] = ""
        if active_request:
            self._dbusservice["/State/RequestId"] = active_request

        self._increment_counter("/Event/FinishedSeq")
        return False

    def _emit_stdout_line(self, line: str):
        self._dbusservice["/Event/StdoutLine"] = line
        self._increment_counter("/Event/StdoutSeq")
        return False

    def _emit_stderr_line(self, line: str):
        self._dbusservice["/Event/StderrLine"] = line
        self._dbusservice["/Result/Error"] = line
        self._increment_counter("/Event/StderrSeq")
        return False

    def _reset_result_state(self, operation_name: str):
        self._dbusservice["/Result/ExitCode"] = 0
        self._dbusservice["/Result/ExitStatus"] = dbus.UInt16(0)
        self._dbusservice["/Result/Error"] = ""
        self._dbusservice["/Event/StdoutLine"] = ""
        self._dbusservice["/Event/StderrLine"] = ""
        self._dbusservice["/State/OperationName"] = operation_name

    def _publish_http_source(self, source: str):
        if not source:
            return False
        if self._start_http_server():
            self._set_http_source_internal(source)
        return False

    def _set_error(self, message: str):
        self._dbusservice["/Result/Error"] = message
        self._dbusservice["/Event/StderrLine"] = message
        self._increment_counter("/Event/StderrSeq")

    def _increment_counter(self, path: str):
        current = int(self._dbusservice[path]) if path in self._dbusservice else 0
        self._dbusservice[path] = dbus.UInt32(current + 1)

    def _set_stream_done(self, state: CommandState, is_stdout: bool):
        with self._lock:
            if self._active is not state:
                return
            if is_stdout:
                state.stdout_done = True
            else:
                state.stderr_done = True

    def _wait_for_streams_done(self, state: CommandState):
        while True:
            with self._lock:
                if self._active is not state:
                    return
                if state.stdout_done and state.stderr_done:
                    return
            threading.Event().wait(0.02)
 
    @staticmethod
    def _resolve_command(args: List[str]):
        family = (args[0] if args else "").strip()
        action = (args[1] if len(args) > 1 else "").strip()
        tail = [str(arg) for arg in args[2:]]

        family_spec = COMMAND_REGISTRY.get(family)
        if not family_spec:
            raise ValueError(f"Unable to resolve helper for command='{family}' args={args}")

        actions = family_spec["actions"]
        action_spec = actions.get(action)
        if action_spec is None:
            raise ValueError(f"Unsupported {family} command: {action}")

        default_spec = family_spec["default"]
        helper_name = action_spec.get("helper_name", default_spec["helper_name"])
        helper_path = action_spec.get("helper_path", default_spec["helper_path"])
        source_files = action_spec.get("source_files")
        prefix_args = list(action_spec.get("prefix_args", []))
        helper_args = prefix_args + [action] + tail
        public_command = f"{family} {action}".strip()
        return helper_name, helper_path, helper_args, source_files, public_command

def main():
    service = OpkgManagerService()
    service.run()

if __name__ == "__main__":
    main()
