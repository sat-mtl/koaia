import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Score.UI as UI
import koaia

ApplicationWindow {
    id: mainWindow
    width: appStyle.windowWidth
    height: appStyle.windowHeight
    minimumWidth: appStyle.windowMinWidth
    minimumHeight: appStyle.windowMinHeight
    visible: true
    title: "koaia"

    DarkStyle {
        id: dark_style
    }
    LightStyle {
        id: light_style
    }

    property var appStyle: {
        if (Application.styleHints.colorScheme === Qt.ColorScheme.Unknown) {
            return dark_style
        }
        return Application.styleHints.colorScheme === Qt.ColorScheme.Dark ? dark_style : light_style
    }
    
    palette {
        // Text colors
        text: appStyle.textColor
        windowText: appStyle.textColor
        buttonText: appStyle.textColor
        brightText: appStyle.textColorOnAccent
        placeholderText: appStyle.textColorSecondary
        
        // Background colors
        window: appStyle.backgroundColor
        base: appStyle.backgroundColorSecondary
        alternateBase: appStyle.backgroundColorTertiary
        
        // Used by FileDialog header/footer
        light: appStyle.backgroundColorSecondary
        midlight: appStyle.backgroundColorTertiary
        mid: appStyle.borderColor
        dark: appStyle.borderColor
        shadow: appStyle.backgroundColor
        
        // Interactive elements
        button: appStyle.buttonBgInactive
        highlight: appStyle.primaryColor
        highlightedText: appStyle.textColorOnAccent
        
        // Links
        link: appStyle.primaryColor
        linkVisited: appStyle.secondaryColor
    }

    AboutDialog {
        id: aboutDialog
        parentWindow: mainWindow
    }
    
    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            id: sidebar
            width: appStyle.sidebarWidth
            Layout.fillHeight: true
            color: appStyle.sidebarBackgroundColor
            
            ColumnLayout {
                id: sidebarColumn
                anchors.fill: parent
                anchors.leftMargin: 0
                anchors.topMargin: appStyle.padding
                anchors.rightMargin: 0
                anchors.bottomMargin: appStyle.padding
                spacing: appStyle.spacing
                
                Image {
                    id: logoImage
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 60
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: appStyle.padding
                    source: "koaia/resources/images/koaia_logo.png"
                    fillMode: Image.PreserveAspectFit
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: aboutDialog.open()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
                
                Item {
                    Layout.fillHeight: true
                }
            }
        }
        
        MainView {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}