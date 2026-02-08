import QtQuick 2.12
import OpkgHelpers 1.0

Item {
    Timer {
        Timer {
            interval: 0
            running: true
            repeat: false
            onTriggered: {
                var r = processRunner;
                r.outputLine.connect(function(line) { console.log("out:", line); });
                r.errorLine.connect(function(line) { console.log("err:", line); });
                r.finished.connect(function(code, status) { console.log("done:", code, status); });
                r.start(["--help"]);
            }
            r.finished.connect(function(code, status) { console.log("done:", code, status); });
            r.start(["--help"]);
        }
    }

    ProcessRunner { id: processRunner }
}
