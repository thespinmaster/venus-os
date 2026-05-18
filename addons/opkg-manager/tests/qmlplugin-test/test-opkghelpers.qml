import QtQuick 2.12
import QtQml 2.12
import OpkgHelpers 1.0

Item {
    Component.onCompleted: {
        processRunner.outputLine.connect(function(line) { console.log("out:", line); });
        processRunner.errorLine.connect(function(line) { console.log("err:", line); });
        processRunner.finished.connect(function(code, status) {
            console.log("done:", code, status);
            Qt.quit();
        });
        processRunner.start(["feed", "type"]);
    }

    OpkgBridge { id: processRunner }
}
