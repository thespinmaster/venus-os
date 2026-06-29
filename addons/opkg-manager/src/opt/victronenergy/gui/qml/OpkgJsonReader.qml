// SYM LINKED
// OpkgJsonReader.qml
//
// Self-contained chunk-based JSON reader for opkg-manager.
// Reads named datasets (e.g. "packages", "feeds") from the
// com.victronenergy.opkgmanager service via the /Chunk/ D-Bus paths.

import QtQuick

QtObject {
	id: root
 
	// Emitted when a dataset has been fully read and parsed.
	signal jsonReady(var jsonData, string jsonText, string name)
	signal jsonError(string error, string name)
	readonly property bool running: _active

	// -- private read-session state --

	property string  _name:          ""
	property var     _callback:      null
	property string  _buffer:        ""
	property string  _sourceVersion: ""
	property int     _nextOffset:    0
	property int     _pendingSeq:    0
	property bool    _active:        false

	// -- request paths (writable) --
	property VeQuickItemAdapter _reqName: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Request/Name"
	}
	property VeQuickItemAdapter _reqOffset: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Request/Offset"
	}
	property VeQuickItemAdapter _reqMaxSize: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Request/MaxSize"
	}
	property VeQuickItemAdapter _reqSeq: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Request/Seq"
	}

	// -- result paths (readable) --
	property VeQuickItemAdapter _resSeq: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Result/Seq"
		onValueChanged: root._onResultSeq(value)
	}
	property VeQuickItemAdapter _resData: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Result/Data"
	}
	property VeQuickItemAdapter _resEndOfData: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Result/EndOfData"
	}
	property VeQuickItemAdapter _resSourceVersion: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Result/SourceVersion"
	}
	property VeQuickItemAdapter _resError: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Chunk/Result/Error"
	}

	property Timer _timeoutTimer: Timer {
		interval: 5000
		repeat: false
		onTriggered: root._fail("Chunk request timed out for: " + root._name)
	}

	// -- public API --

	function readAll(name, callback) {
		if (_active) {
			var busyError = "OpkgJsonReader is busy"
			jsonError(busyError, name)
			if (callback) {
				callback(busyError, null, null)
			}
			return
		}
		_name          = name
		_callback      = callback
		_buffer        = ""
		_sourceVersion = ""
		_nextOffset    = 0
		_active        = true
		_requestNextChunk()
	}

	// -- private --

	function _requestNextChunk() {
		var currentSeq = (_reqSeq.value !== undefined && _reqSeq.value !== null)
						 ? parseInt(_reqSeq.value) : 0
		_pendingSeq = currentSeq + 1

		_reqName.setValue(_name)
		_reqOffset.setValue(_nextOffset)
		_reqMaxSize.setValue(32768)
		_timeoutTimer.restart()
		_reqSeq.setValue(_pendingSeq)
	}

	function _onResultSeq(seq) {
		if (!_active)
			return
		if (seq === undefined || seq === null)
			return
		if (parseInt(seq) !== _pendingSeq)
			return

		_timeoutTimer.stop()

		var errText = _resError.value || ""
		if (errText.length > 0) {
			_fail("GetChunkData error (" + _name + "): " + errText)
			return
		}

		var chunkText = _resData.value || ""
		if (chunkText.length > 0) {
			_buffer += chunkText
			_nextOffset += chunkText.length
		}

		var version = _resSourceVersion.value || ""
		if (_sourceVersion.length === 0) {
			_sourceVersion = version
		} else if (version.length > 0 && version !== _sourceVersion) {
			_fail("Source changed during read (version mismatch for: " + _name + ")")
			return
		}

		var endOfData = parseInt(_resEndOfData.value || 0)
		if (endOfData) {
			_complete()
		} else {
			_requestNextChunk()
		}
	}

	function _complete() {
		var cb = _callback
		var result = _buffer
		var name = _name
		var parsed
		var trimmed = result.trim()

		if (trimmed.length > 0 && trimmed[0] !== "{" && trimmed[0] !== "[") {
			_fail("Unexpected payload format (" + name + "): expected JSON text")
			return
		}

		try {
			parsed = JSON.parse(result)
		} catch (e) {
			_fail("JSON parse error (" + name + "): " + e)
			return
		}

		_reset()
		jsonReady(parsed, result, name)
		if (cb) {
			cb(null, result, parsed)
		}
	}

	function _fail(reason) {
		console.warn("OpkgJsonReader: " + reason)
		var cb = _callback
		var name = _name
		_reset()
		jsonError(reason, name)
		if (cb) {
			cb(reason, null, null)
		}
	}

	function _reset() {
		_active        = false
		_callback      = null
		_buffer        = ""
		_sourceVersion = ""
		_name          = ""
		_nextOffset    = 0
		_pendingSeq    = 0
		_timeoutTimer.stop()
	}
}