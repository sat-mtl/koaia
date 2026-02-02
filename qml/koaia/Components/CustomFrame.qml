import QtQuick
import QtQuick.Layouts
import Score.UI as UI
import koaia

Rectangle {
    id: frame

    property real aspectRatio: 1280 / 720
    property string process: ""
    property int port: 0
    property bool showTexture: true

    property int frameHeight: 350

    Layout.preferredHeight: frameHeight
    Layout.minimumHeight: 200

    Layout.preferredWidth: frameHeight * aspectRatio
    Layout.minimumWidth: 350

    Layout.fillWidth: true

    color: "transparent"
    radius: appStyle.borderRadius
    border.color: appStyle.borderColor
    border.width: 1

    Item {
        anchors.fill: parent
        anchors.margins: 1
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: frame.radius - 1
            color: appStyle.backgroundColorTertiary
            layer.enabled: true
            layer.smooth: true

            UI.TextureSource {
                anchors.fill: parent
                process: frame.process
                port: frame.port
                visible: frame.showTexture
            }
        }
    }
}
