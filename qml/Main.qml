import QtQuick
import QtQuick.Controls.Basic
import koaia

ApplicationWindow {
    id: mainWindow
    width: 800
    height: 600
    visible: true
    title: "koaia"
    
    DarkStyle { id: appStyle }
    
    Rectangle {
        anchors.fill: parent
        color: appStyle.backgroundColor
    }
}
