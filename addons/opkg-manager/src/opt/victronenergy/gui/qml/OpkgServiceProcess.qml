import QtQuick 2
import com.victron.velib 1.0

QtObject {
	id: root

	property string operationName: ""
	property string jsonResult: jsonResultItem.valid && jsonResultItem.value !== undefined ? String(jsonResultItem.value) : ""
	property bool running: runningItem.valid && Number(runningItem.value) !== 0
	property bool stopping: stoppingItem.valid && Number(stoppingItem.value) !== 0

	property bool _initialized: false
	property int _lastStdoutSeq: 0
	property int _lastStderrSeq: 0
	property int _lastFinishedSeq: 0

	signal outputLine(string line)
	signal errorLine(string line)
	signal finished(int exitCode, int exitStatus)

	function start(args) {
		argsJsonItem.setValue(JSON.stringify(args || []))
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
			root.finished(Number(exitCodeItem.value) || 0, Number(exitStatusItem.value) || 0)
		}
	}

	property var exitCodeItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Result/ExitCode"
	}

	property var exitStatusItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Result/ExitStatus"
	}

	property var jsonResultItem: VBusItem {
		bind: "com.victronenergy.opkgmanager/Result/Json"
	}
}
