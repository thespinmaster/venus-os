import QtQuick 2.12
import QtQml 2.12
import OpkgHelpers 1.0

Item {
    property int step: 0

    Component.onCompleted: {
        processRunner.helperPath = "./opkg-common-runner";
        processRunner.outputLine.connect(function(line) { console.log("out:", line); });
        processRunner.errorLine.connect(function(line) { console.log("err:", line); });
        processRunner.finished.connect(handleFinished);
        processRunner.start(["add-feed", "custom-feed", "http://example.com"]);
    }

    function handleFinished(code, status) {
        console.log("done:", code, status);
        if (step === 0 && code === 0) {
            step = 1;
            //processRunner.start(["remove-feed", "custom-feed"]);
            return;
        }
        Qt.quit();
    }

    ProcessRunner { id: processRunner }
}
