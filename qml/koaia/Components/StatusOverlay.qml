import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    
    property var sliders: []
    
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 8
    z: 10
    
    width: statusColumn.implicitWidth + 16
    height: statusColumn.implicitHeight + 12
    
    color: "#000000"
    opacity: 0.7
    radius: 6
    
    Column {
        id: statusColumn
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            text: "Active Layers:"
            color: "#FFFFFF"
            font.pixelSize: 10
            font.bold: true
        }
        
        Repeater {
            model: root.sliders
            
            Row {
                spacing: 6
                Rectangle { 
                    width: 8
                    height: 8
                    radius: 4
                    color: modelData.slider.value > 0.01 ? "#4CD964" : "#444444"
                }
                Text { 
                    text: modelData.name
                    color: "#FFFFFF"
                    font.pixelSize: 9 
                }
            }
        }
    }
}
