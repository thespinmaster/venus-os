import QtQuick 2.12
import QtQml 2.12
import OpkgHelpers 1.0

Item {
    property int step: 0

    Component.onCompleted: {
        opkgBridge.outputLine.connect(function(line) { console.log("out:", line); });
        opkgBridge.errorLine.connect(function(line) { console.log("err:", line); });
        opkgBridge.finished.connect(handleFinished);
        opkgBridge.start(["feed", "type"]);
    }

    function handleFinished(code, status) {
        console.log("done:", code, status);
        if (step === 0 && code === 0) {
            step = 1;
            //opkgBridge.start(["remove-feed", "custom-feed"]);
            return;
        }
        Qt.quit();
    }

    OpkgBridge { id: opkgBridge }
}
