import QtQuick 2
import com.victron.velib 1.0

QtObject {
	id: root

	property string operationName: ""
 
	property bool running: runningItem.valid && Number(runningItem.value) !== 0
	property bool stopping: stoppingItem.valid && Number(stoppingItem.value) !== 0

	property bool _initialized: false
	property int _lastStdoutSeq: 0
	property int _lastStderrSeq: 0
	property int _lastFinishedSeq: 0

	signal outputLine(string line)
	signal errorLine(string line)
	signal finished(int exitCode, int exitStatus)
	signal httpJsonReady(string jsonText)
	signal httpJsonError(string message)

	function start(args) {
		var normalizedArgs = _normalizeArgs(args)
 
		argsJsonItem.setValue(JSON.stringify(normalizedArgs))
		console.log("PPP:start:" + JSON.stringify(normalizedArgs))
		startItem.setValue((Number(startItem.value) || 0) + 1)
	}

	function stop() {
		cancelItem.setValue((Number(cancelItem.value) || 0) + 1)
	}

	function cleanup() {
		if (running) {
			stop()
		}
	}

	function waitForFinished() {
		return !running
	}

	function requestPackagesFromServer() {
		start(["package", "list"])
	}

	function _normalizeArgs(args) {
		if (args === undefined || args === null)
			return []
		if (Array.isArray(args))
			return args.map(function(arg) { return String(arg) })
		return [String(args)]
	}
 
	function fetchJsonFromHttp() {
		console.log("PPP:fetchJsonFromHttp:1")
		if (!httpServerSourceItem.valid || httpServerSourceItem.value == undefined)
			return
		console.log("PPP:fetchJsonFromHttp:2")
		var xhr = new XMLHttpRequest()
		xhr.onreadystatechange = function() {
			if (xhr.readyState !== XMLHttpRequest.DONE)
				return

			// Signal download completion back to service so it can stop HTTP server.
			httpServerSourceItem.setValue("")

			if (xhr.status !== 200 && xhr.status !== 0) {
				root.httpJsonError("Failed to load package JSON, status: " + xhr.status)
				return
			}

			root.httpJsonReady(String(xhr.responseText || ""))
		}
 
		var sourceFile = String(root.httpSource || "packages.json")
		sourceFile = sourceFile.replace(/^\/+/, "")
		xhr.open("GET", "http://127.0.0.1:8888/" + sourceFile)
		xhr.send()
	}

	Component.onCompleted: {
		_lastStdoutSeq = Number(stdoutSeqItem.value) || 0
		_lastStderrSeq = Number(stderrSeqItem.value) || 0
		_lastFinishedSeq = Number(finishedSeqItem.value) || 0
		_initialized = true
	}

	property var argsJsonItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Request/ArgsJson"
	}

	property var startItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Request/Start"
	}

	property var cancelItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Request/Cancel"
	}
 
	property var runningItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/State/Running"
	}

	property var stoppingItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/State/Stopping"
	}

	property var stdoutLineItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Event/StdoutLine"
	}

	property var stdoutSeqItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Event/StdoutSeq"
		onValueChanged: {
			var seq = Number(value) || 0
			if (!root._initialized || seq === root._lastStdoutSeq)
				return
			root._lastStdoutSeq = seq
			root.outputLine(String(stdoutLineItem.value || ""))
		}
	}

	property var stderrLineItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Event/StderrLine"
	}

	property var stderrSeqItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Event/StderrSeq"
		onValueChanged: {
			var seq = Number(value) || 0
			if (!root._initialized || seq === root._lastStderrSeq)
				return
			root._lastStderrSeq = seq
			root.errorLine(String(stderrLineItem.value || ""))
		}
	}

	property var finishedSeqItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Event/FinishedSeq"
		onValueChanged: {
			var seq = Number(value) || 0
			if (!root._initialized || seq === root._lastFinishedSeq)
				return
			root._lastFinishedSeq = seq

			var exitCode = Number(exitCodeItem.value) || 0
			var exitStatus = Number(exitStatusItem.value) || 0
			console.log("PPP:finished")
			root.finished(exitCode, exitStatus)
 
		}
	}

	property var exitCodeItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Result/ExitCode"
	}

	property var exitStatusItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Result/ExitStatus"
	}

	property var httpServerSourceItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/HttpServer/Source"
		onValueChanged: fetchJsonFromHttp()
	}
}
