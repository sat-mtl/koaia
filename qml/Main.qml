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
    property var logger

    // CUDA availability check
    readonly property bool hasCuda: System.availableCudaDevice() > 0

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

    property int currentViewIndex: 0
    readonly property int mainViewIndex: 0
    readonly property int modelViewIndex: 1
    readonly property int logViewIndex: 2

    AboutDialog {
        id: aboutDialog
        parentWindow: mainWindow
    }
    
    // Error message when no CUDA device is available
    Rectangle {
        id: noCudaMessage
        anchors.fill: parent
        color: appStyle.backgroundColor
        visible: !hasCuda

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Image {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                Layout.alignment: Qt.AlignHCenter
                source: "koaia/resources/images/koaia_logo.png"
                fillMode: Image.PreserveAspectFit
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "CUDA Device Not Found"
                font.pixelSize: appStyle.fontSizeTitle
                font.bold: true
                color: appStyle.textColor
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 400
                text: "This application requires an NVIDIA GPU with CUDA support.\n\nPlease ensure you have an NVIDIA GPU of at least generation RTX 3xxx (Ampere architecture or newer) installed with the appropriate drivers."
                font.pixelSize: appStyle.fontSizeBody
                color: appStyle.textColorSecondary
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                text: "Exit"
                font.pixelSize: appStyle.fontSizeBody
                onClicked: Qt.exit(0)
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 0
        visible: hasCuda

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
                CustomButton {
                    id: runButton
                    text: "RUN"
                    Layout.fillWidth: true
                    Layout.topMargin: appStyle.spacing
                    isActive: currentViewIndex === mainViewIndex
                    onClicked: currentViewIndex = mainViewIndex
                }
                
                CustomButton {
                    id: modelButton
                    text: "MODEL"
                    Layout.fillWidth: true
                    Layout.topMargin: appStyle.spacing
                    isActive: currentViewIndex === modelViewIndex
                    onClicked: currentViewIndex = modelViewIndex
                }
                
                CustomButton {
                    id: logButton
                    text: "LOGS"
                    Layout.fillWidth: true
                    Layout.topMargin: appStyle.spacing
                    isActive: currentViewIndex === logViewIndex
                    onClicked: currentViewIndex = logViewIndex
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
        
        StackLayout {
            id: stackView
            enabled: hasCuda
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: currentViewIndex

            MainView {
            }
            ModelView {
            }
            LogView {
            }
        }
    }
}
