import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import koaia

Pane {
    id: logView
    background: Rectangle {
        color: appStyle.backgroundColor
    }

    function log(message) {
        var time = new Date();
        var timestamp = time.getHours() + ":" + 
                       (time.getMinutes() < 10 ? "0" : "") + time.getMinutes() + ":" + 
                       (time.getSeconds() < 10 ? "0" : "") + time.getSeconds();
        logTextArea.append("[" + timestamp + "] " + message);
        console.log(message);
    }
    
    function clear() {
        logTextArea.text = "";
    }

    Component.onCompleted: {
        if (mainWindow) {
            mainWindow.logger = logView;
        }
        log("Log view initialized");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: appStyle.padding
        spacing: appStyle.spacing

        CustomLabel {
            text: "Application Log"
            font.bold: true
            font.pixelSize: appStyle.fontSizeTitle
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextArea {
                id: logTextArea
                text: ""
                readOnly: true
                wrapMode: TextEdit.Wrap
                font.family: appStyle.fontFamily
                font.pixelSize: appStyle.fontSizeBody
                color: appStyle.textColor
            }
        }

        RowLayout {
            spacing: appStyle.spacing

            Button {
                text: "Clear Log"
                font.family: appStyle.fontFamily
                onClicked: {
                    logView.clear()
                }
            }

            Button {
                text: "Test Log"
                font.family: appStyle.fontFamily
                onClicked: {
                    logView.log("Test log message at " + new Date().toLocaleTimeString())
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}

