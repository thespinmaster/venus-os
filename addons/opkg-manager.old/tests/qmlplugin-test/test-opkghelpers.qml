import QtQuick 2.12
import QtQml 2.12
import OpkgHelpers 1.0

Item {
    Component.onCompleted: {
        opkgBridge.outputLine.connect(function(line) { console.log("out:", line); });
        opkgBridge.errorLine.connect(function(line) { console.log("err:", line); });
        opkgBridge.finished.connect(function(code, status) {
            console.log("done:", code, status);
            Qt.quit();
        });
        opkgBridge.start(["feed", "type"]);
    }

    OpkgBridge { id: opkgBridge }
}
