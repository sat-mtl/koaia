import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Score.UI as UI
import koaia

RowLayout {
    property string labelText: ""
    property var port: null
    property real from: 0
    property real to: 1
    property real initialValue: 0
    property real stepSize: 0.01

    Layout.fillWidth: true

    Label {
        text: labelText
        Layout.preferredWidth: labelText ? 80 : 0
        visible: labelText !== ""
        font.pixelSize: appStyle.fontSizeBody
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        from: parent.from
        to: parent.to
        value: parent.initialValue
        stepSize: parent.stepSize

        UI.PortSource on value {
            port: parent.port
        }

        Component.onCompleted: {
            if (parent.port) {
                Score.setValue(parent.port, value)
            }
        }

        onValueChanged: {
            if (parent.port) {
                try {
                    Score.setValue(parent.port, value)
                } catch(e) {
                    console.warn("Could not set value on port:", e)
                }
            }
        }
    }
}
