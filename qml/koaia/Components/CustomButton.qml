import QtQuick
import koaia

Item {
    id: root
    
    property alias text: buttonText.text
    property alias color: buttonBackground.color
    property bool isActive: false
    signal clicked
    
    height: appStyle.sidebarButtonHeight
    clip: false
    
    Rectangle {
        id: buttonBackground
        anchors.fill: parent
        color: mouseArea.containsMouse && !root.isActive 
               ? appStyle.sidebarHoverColor 
               : appStyle.sidebarBackgroundColor
        radius: 0
        
        Behavior on color {
            ColorAnimation { duration: appStyle.animationDuration / 2 }
        }
        
        Rectangle {
            id: activeIndicator
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: appStyle.primaryColor
            visible: root.isActive
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clicked()
            cursorShape: Qt.PointingHandCursor
        }
        
        Text {
            id: buttonText
            text: "Button"
            anchors.centerIn: parent
            color: root.isActive 
                   ? appStyle.primaryColor 
                   : (mouseArea.containsMouse ? appStyle.sidebarTextColor : appStyle.sidebarTextColorInactive)
            font.family: appStyle.fontFamily
            font.pixelSize: appStyle.fontSizeBody
            font.bold: root.isActive
            
            Behavior on color {
                ColorAnimation { duration: appStyle.animationDuration / 2 }
            }
        }
    }
}
