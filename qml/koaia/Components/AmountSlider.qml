import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Score.UI as UI
import koaia

RowLayout {
    id: root
    
    property string label: "Amount"
    property real value: 0.0
    property real from: 0.0
    property real to: 1.0
    property var port: null
    property bool enabled: true
    
    property alias slider: slider
    
    Layout.fillWidth: true
    
    Label {
        text: root.label
        Layout.preferredWidth: 60
        font.pixelSize: appStyle.fontSizeBody
        color: root.enabled ? appStyle.textColor : appStyle.textColorSecondary
    }
    
    Slider { 
        id: slider
        Layout.fillWidth: true
        from: root.from
        to: root.to
        value: root.enabled ? root.value : 0.0
        enabled: root.enabled
        opacity: root.enabled ? 1.0 : 0.5
        
        UI.PortSource on value {
            port: root.port
        }
        
        onValueChanged: {
            if (root.enabled) {
                root.value = value
            } else {
                value = 0.0
            }
        }
    }
    
    Rectangle {
        width: 12
        height: 12
        radius: 6
        color: root.enabled && slider.value > 0.01 ? "#4CD964" : "#8E8E93"
        opacity: root.enabled ? 1.0 : 0.5
        border.color: "#FFFFFF"
        border.width: 1
    }
}
