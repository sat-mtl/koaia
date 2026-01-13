import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import io.ossia.components as CustomAppComponents

import Score.UI as UI

ApplicationWindow {
    id: root
    visible: true
    width: 800
    height: 800
    title: "My Custom ossia score App"

    // Custom color scheme
    color: "#1e1e2e"


    component PrettyText : Text {
        color: "#cdd6f4"
        font.pixelSize: 14
        wrapMode: Text.WordWrap
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#2a2a3e"
            radius: 10

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5

                PrettyText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Welcome to Your Custom App"
                    font.pixelSize: 24
                    font.bold: true
                }

                PrettyText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Powered by ossia score"
                    font.pixelSize: 14
                }
            }
        }

        // Main content area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.margins: 30
                spacing: 20

                PrettyText {
                    text: "Getting Started"
                    font.pixelSize: 20
                    font.bold: true
                }

                PrettyText {
                    Layout.fillWidth: true
                    text: "This is a template for creating custom ossia score applications.\n\n" + "You can customize this QML interface to create your own unique user experience.\n\n" + "Features available:\n" + "• Custom QML user interfaces\n" + "• Automatic score file loading\n" + "• Multi-platform packaging (Linux, macOS, Windows)\n" + "• Native launchers for each platform"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    lineHeight: 1.4
                }

                Item {
                    Layout.fillHeight: true
                }

                // Control buttons
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 15

                    Button {
                        text: "Play"
                        font.pixelSize: 14
                        implicitWidth: 100
                        implicitHeight: 40

                        background: Rectangle {
                            color: parent.pressed ? "#94e2d5" : (parent.hovered ? "#89dceb" : "#74c7ec")
                            radius: 6
                        }

                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "#1e1e2e"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: Score.play()
                    }

                    Button {
                        text: "Stop"
                        font.pixelSize: 14
                        implicitWidth: 100
                        implicitHeight: 40

                        background: Rectangle {
                            color: parent.pressed ? "#f9e2af" : (parent.hovered ? "#f5c2e7" : "#cba6f7")
                            radius: 6
                        }

                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "#1e1e2e"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: Score.stop()
                    }
                }
            }
            ColumnLayout {
                PrettyText {
                    text: "Viewing a viewport:"
                }
                UI.TextureSource {
                    id: outputTexture
                    anchors.margins: 30
                    width: 200
                    height: 200
                    process: "Triangle Square Twist"
                    port: 0
                }
                PrettyText {
                    text: "Operating a control: LFO frequency"
                }
                Slider {
                    UI.PortSource on value {
                        process: "LFO"
                        port: 0
                    }
                }

                PrettyText {
                    text: "Reading the value of a control: LFO frequency"
                }
                PrettyText {
                    UI.PortSource on text {
                        process: "LFO"
                        port: "Freq."
                    }
                }

                PrettyText {
                    text: "Reading the value of an inlet:"
                }
                PrettyText {
                    UI.PortSource on text {
                        process: "Value display"
                        port: 0
                    }
                }

                PrettyText {
                    text: "Reading the value of any address: OSC:/foo"
                }
                PrettyText {
                    UI.AddressSource on text {
                        address: "OSC:/foo"
                        sendUpdates: false
                    }
                }

                PrettyText {
                    text: "Setting the value of any address: OSC:/bar"
                }
                Slider {
                    UI.AddressSource on value {
                        address: "OSC:/bar"
                        receiveUpdates: false
                    }
                }
            }
        }

        // Status bar
        CustomAppComponents.MyComponent {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#2a2a3e"
            radius: 10
        }
    }
}
