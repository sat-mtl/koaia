import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Score.UI as UI
import koaia
import ca.qc.sat.qmlcomponents

ApplicationWindow {
    id: mainWindow
    width: 900
    height: 900
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: "koaia"
    property var logger

    // CUDA availability check
    readonly property bool hasCuda: System.availableCudaDevice() > 0
    readonly property bool isWin32: Qt.platform.os === "windows"

    // Required packages
    readonly property var requiredPackages: [
        { uuid: "6aa9d4fd-a45b-4736-af8a-56168b48af42", name: "uv (Python package manager)" },
        { uuid: "28d97cbc-bc84-4e74-9bc2-fe0f0fccf87c", name: "CUDA libraries" },
        { uuid: "d0add344-cb23-4d3f-817b-3619505565d1", name: "LibreDiffusion" }
    ]

    // Track installed packages
    property var installedPackageUuids: []
    property bool allPackagesInstalled: false
    property bool isCheckingPackages: true
    property bool needsRestart: false  // True when packages were installed this session

    function checkInstalledPackages() {
        var installed = Library.installedPackages()
        var uuids = []
        for (var i = 0; i < installed.length; i++) {
            uuids.push(installed[i].uuid)
        }

        var previouslyInstalled = installedPackageUuids.length
        installedPackageUuids = uuids

        // Check if all required packages are installed
        var allInstalled = true
        for (var j = 0; j < requiredPackages.length; j++) {
            if (uuids.indexOf(requiredPackages[j].uuid) === -1) {
                allInstalled = false
                break
            }
        }

        // If packages were installed this session, mark that restart is needed
        if (allInstalled && !allPackagesInstalled && previouslyInstalled > 0) {
            needsRestart = true
        }

        allPackagesInstalled = allInstalled
        isCheckingPackages = false
    }

    function isPackageInstalled(uuid) {
        return installedPackageUuids.indexOf(uuid) !== -1
    }

    Component.onCompleted: {
        Library.refreshAvailablePackages()
        checkInstalledPackages()
    }

    // Timer to periodically check package installation status
    Timer {
        id: packageCheckTimer
        interval: 2000
        repeat: true
        running: !allPackagesInstalled
        onTriggered: checkInstalledPackages()
    }

    // Drive the shared Theme from the OS colour scheme (dark unless the system
    // asks for light) and pin koaia's teal accent — every other token is
    // palette-driven by the shared module.
    Binding {
        target: Theme
        property: "dark"
        value: Application.styleHints.colorScheme !== Qt.ColorScheme.Light
    }
    Binding {
        target: Theme
        property: "primaryColor"
        value: "#006B85"
    }
    
    palette {
        // Text colors
        text: Theme.textColor
        windowText: Theme.textColor
        buttonText: Theme.textColor
        brightText: Theme.textColorOnAccent
        placeholderText: Theme.textColorSecondary
        
        // Background colors
        window: Theme.backgroundColor
        base: Theme.backgroundColorSecondary
        alternateBase: Theme.backgroundColorTertiary
        
        // Used by FileDialog header/footer
        light: Theme.backgroundColorSecondary
        midlight: Theme.backgroundColorTertiary
        mid: Theme.borderColor
        dark: Theme.borderColor
        shadow: Theme.backgroundColor
        
        // Interactive elements
        button: Theme.buttonBgInactive
        highlight: Theme.primaryColor
        highlightedText: Theme.textColorOnAccent
        
        // Links
        link: Theme.primaryColor
        linkVisited: Theme.secondaryColor
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
        color: Theme.backgroundColor
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
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: Theme.textColor
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 400
                text: "This application requires an NVIDIA GPU with CUDA support.\n\nPlease ensure you have an NVIDIA GPU of at least generation RTX 3xxx (Ampere architecture or newer) installed with the appropriate drivers."
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textColorSecondary
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                text: "Exit"
                font.pixelSize: Theme.fontSizeBody
                onClicked: Qt.exit(0)
            }
        }
    }

    // Missing packages screen
    Rectangle {
        id: missingPackagesScreen
        anchors.fill: parent
        color: Theme.backgroundColor
        visible: hasCuda && !allPackagesInstalled

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            width: Math.min(500, parent.width - 40)

            Image {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                Layout.alignment: Qt.AlignHCenter
                source: "koaia/resources/images/koaia_logo.png"
                fillMode: Image.PreserveAspectFit
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Required Packages"
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: Theme.textColor
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: "The following packages are required to run Koaia. Please install any missing packages. This may take several minutes per package."
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textColorSecondary
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            // Package list
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: packageListColumn.implicitHeight + 20
                color: Theme.backgroundColorSecondary
                border.color: Theme.borderColor
                border.width: 1
                radius: Theme.borderRadius

                ColumnLayout {
                    id: packageListColumn
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Repeater {
                        model: requiredPackages

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Status icon
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: isPackageInstalled(modelData.uuid) ? "#4CAF50" : Theme.borderColor

                                Label {
                                    anchors.centerIn: parent
                                    text: isPackageInstalled(modelData.uuid) ? "\u2713" : ""
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "white"
                                }
                            }

                            // Package name
                            Label {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeBody
                                color: Theme.textColor
                            }

                            // Status / Install button
                            Button {
                                visible: !isPackageInstalled(modelData.uuid)
                                text: "Install"
                                font.pixelSize: Theme.fontSizeSmall
                                onClicked: Library.installPackage(modelData.uuid)
                            }

                            Label {
                                visible: isPackageInstalled(modelData.uuid)
                                text: "Installed"
                                font.pixelSize: Theme.fontSizeSmall
                                color: "#4CAF50"
                            }
                        }
                    }
                }
            }

            // Install all button
            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                text: "Install All Missing Packages"
                font.pixelSize: Theme.fontSizeBody
                visible: !allPackagesInstalled
                onClicked: {
                    for (var i = 0; i < requiredPackages.length; i++) {
                        if (!isPackageInstalled(requiredPackages[i].uuid)) {
                            Library.installPackage(requiredPackages[i].uuid)
                        }
                    }
                }
            }

            // Restart required message
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 10
                visible: allPackagesInstalled && needsRestart
                color: "#2E7D32"
                radius: Theme.borderRadius
                implicitHeight: restartColumn.implicitHeight + 20

                ColumnLayout {
                    id: restartColumn
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "All packages installed successfully!"
                        font.pixelSize: Theme.fontSizeBody
                        font.bold: true
                        color: "white"
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        text: "Please restart Koaia to complete the setup."
                        font.pixelSize: Theme.fontSizeBody
                        color: "white"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Quit Koaia"
                        font.pixelSize: Theme.fontSizeBody
                        onClicked: Qt.exit(0)
                    }
                }
            }

            // Progress indicator
            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: !allPackagesInstalled
                text: "Checking installation status..."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textColorSecondary

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                }
            }

            // Restart note (shown while installing)
            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: 10
                visible: !allPackagesInstalled
                text: "Note: After all packages are installed, you will need to restart Koaia."
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                color: Theme.textColorSecondary
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 0
        visible: hasCuda && allPackagesInstalled

        Rectangle {
            id: sidebar
            width: Theme.sidebarWidth
            Layout.fillHeight: true
            color: Theme.sidebarBackgroundColor
            
            ColumnLayout {
                id: sidebarColumn
                anchors.fill: parent
                anchors.leftMargin: 0
                anchors.topMargin: Theme.padding
                anchors.rightMargin: 0
                anchors.bottomMargin: Theme.padding
                spacing: Theme.spacing
                
                Image {
                    id: logoImage
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 60
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.padding
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
                    Layout.topMargin: Theme.spacing
                    isActive: currentViewIndex === mainViewIndex
                    onClicked: currentViewIndex = mainViewIndex
                }
                
                CustomButton {
                    id: modelButton
                    text: "MODEL"
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing
                    isActive: currentViewIndex === modelViewIndex
                    onClicked: currentViewIndex = modelViewIndex
                }
                
                CustomButton {
                    id: logButton
                    text: "LOGS"
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing
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
                id: logViewInstance
                title: "Application Log"
                Component.onCompleted: mainWindow.logger = logViewInstance
            }
        }
    }
}
