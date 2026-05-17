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
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib # type: ignore

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
EXT_DIR = os.path.join(THIS_DIR, "ext")

if EXT_DIR not in sys.path:
    sys.path.insert(0, EXT_DIR)

from vedbus import VeDbusService # type: ignore

from opkg_helpers import create_json_feeds_list, send_props_as_json, get_stable_tty_process_pid


SERVICE_NAME = "com.victronenergy.opkgmanager"
VERSION = "2.0.0"

LIB_FOLDER_PATH=f"{THIS_DIR}/libs"

INLINE_JSON_COMMANDS = {
    ("feed", "list"),
    ("package", "list"),
    ("device", "detect"),
}


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
    stdout_lines: List[str] = field(default_factory=list)
    stderr_lines: List[str] = field(default_factory=list)


class OpkgManagerService:
        
    @dbus.service.method(dbus_interface='com.example.Sample',
                         in_signature='v', out_signature='s')
    def GetJsonResult():
        pass

    def __init__(self):
        DBusGMainLoop(set_as_default=True)

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
        self._dbusservice.add_path("/Result/Json", "", valuetype=dbus.String)
        self._dbusservice.add_path("/Result/Error", "", valuetype=dbus.String)

        self._dbusservice.register()
        self._loop = GLib.MainLoop()

    def run(self):
        self._loop.run()

    def _on_start_requested(self, _path, _value):
        GLib.idle_add(self._start_command)
        return True

    def _on_cancel_requested(self, _path, _value):
        GLib.idle_add(self._cancel_command)
        return True

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
            helper_name, helper_path, helper_args, operation_name = self._resolve_command(args)
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
            self._finish_command(None, 1, 1, "")
            return False

        state = CommandState(
            request_id=str(uuid.uuid4()),
            helper_name=helper_name,
            helper_path=helper_path,
            args=helper_args,
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
                    state.stdout_lines.append(line)
                    if not self._is_structured_result_line(state, line):
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

        json_result = self._extract_json_result(state)
        GLib.idle_add(self._finish_command, state, int(return_code), int(exit_status), json_result)

    def _finish_command(self, state: Optional[CommandState], exit_code: int, exit_status: int, json_result: str):
        active_request = ""

        with self._lock:
            if self._active is state:
                active_request = state.request_id if state else ""
                self._active = None

        self._dbusservice["/Result/ExitCode"] = int(exit_code)
        self._dbusservice["/Result/ExitStatus"] = dbus.UInt16(exit_status)
        self._dbusservice["/Result/Json"] = json_result or ""
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
        self._dbusservice["/Result/Json"] = ""
        self._dbusservice["/Result/Error"] = ""
        self._dbusservice["/Event/StdoutLine"] = ""
        self._dbusservice["/Event/StderrLine"] = ""
        self._dbusservice["/State/OperationName"] = operation_name

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

    def _extract_json_result(self, state: CommandState) -> str:
        if not state.args:
            return ""

        if (state.helper_name, state.args[0]) not in INLINE_JSON_COMMANDS:
            return ""

        for line in reversed(state.stdout_lines):
            candidate = line.strip()
            if not candidate:
                continue
            if os.path.isfile(candidate):
                return self._read_json_file(candidate)
            if self._looks_like_json(candidate):
                return candidate

        return ""

    def _is_structured_result_line(self, state: CommandState, line: str) -> bool:
        if not state.args:
            return False
        if (state.helper_name, state.args[0]) not in INLINE_JSON_COMMANDS:
            return False

        candidate = line.strip()
        if not candidate:
            return False
        return os.path.isfile(candidate) or self._looks_like_json(candidate)

    @staticmethod
    def _looks_like_json(candidate: str) -> bool:
        try:
            json.loads(candidate)
            return True
        except Exception:
            return False

    @staticmethod
    def _read_json_file(file_path: str) -> str:
        try:
            with open(file_path, "r", encoding="utf-8") as file_obj:
                text = file_obj.read()
            json.loads(text)
            return text
        except Exception:
            return ""

    @staticmethod
    def _resolve_command(args: List[str]):
        family = (args[0] if args else "").strip()
        action = (args[1] if len(args) > 1 else "").strip()
        tail = [str(arg) for arg in args[2:]]

        if family == "feed":
            return OpkgManagerService._resolve_feed_command(action, tail)
        if family == "package":
            return OpkgManagerService._resolve_package_command(action, tail)
        if family == "device":
            return OpkgManagerService._resolve_device_command(action, tail)
        if family == "test":
            return OpkgManagerService._resolve_test_command(action, tail)
        
        raise ValueError(f"Unable to resolve helper for command='{family}' args={args}")
    
    @staticmethod
    def _resolve_test_command(action: str, tail: List[str]):
        public_command = f"test {action}".strip()
        lib = f"{LIB_FOLDER_PATH}/test"
        if action in {"test1", "test2", "test3", "hello-world"}:
            return "test", lib, [action] + tail, public_command
        raise ValueError(f"Unsupported device command: {action}")

    @staticmethod
    def _resolve_feed_command(action: str, tail: List[str]):
        public_command = f"feed {action}".strip()
        lib = f"{LIB_FOLDER_PATH}/feed"
        no_tail_actions = {"list", "type"}
        if action in {"list", "add", "edit", "remove", "set", "type"}:
            args = [action] if action in no_tail_actions else [action] + tail
            return "feed", lib, args, public_command
        raise ValueError(f"Unsupported feed command: {action}")

    @staticmethod
    def _resolve_package_command(action: str, tail: List[str]):
        public_command = f"package {action}".strip()
        lib = f"{LIB_FOLDER_PATH}/package"
        if action in {"list", "install", "remove", "upgrade"}:
            return "package", lib, [action] + tail, public_command
        raise ValueError(f"Unsupported package command: {action}")

    @staticmethod
    def _resolve_device_command(action: str, tail: List[str]):
        public_command = f"device {action}".strip()
        lib = f"{LIB_FOLDER_PATH}/device"
        if action in {"detect", "apply", "remove"}:
            return "device", lib, [action] + tail, public_command
        raise ValueError(f"Unsupported device command: {action}")


def main():
    service = OpkgManagerService()
    service.run()


if __name__ == "__main__":
    main()
