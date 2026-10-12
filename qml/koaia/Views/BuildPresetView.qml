import QtCore
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import koaia
import "../Scripts/BuildPresets.js" as BuildPresets

// Browser for the engine-build presets, laid out like livepose's PresetView:
// cards grouped by family, a dot showing whether the bundle is already on disk,
// and a click that fills in the builder rather than starting anything.
//
// This lists BUILD presets only. The StreamDiffusion node's own .scp presets are
// a different thing -- they configure a bundle that already exists, there are
// several per bundle, and they belong next to the run controls, not next to a
// 15-45 minute GPU job.
Pane {
    id: presetView
    background: Rectangle { color: appStyle.backgroundColor }

    // The ModelView instance the presets are applied to (wired in Main.qml).
    property var builder: null

    // Bumped to re-evaluate the "is this bundle built?" checks, which read the
    // filesystem and so cannot be plain bindings.
    property int refreshKey: 0

    Settings {
        id: presetSettings
        category: "BuildPresets"
        property string enginesRoot: ""
    }

    readonly property string defaultEnginesRoot:
        urlToLocalPath(StandardPaths.writableLocation(StandardPaths.DocumentsLocation))
        + "/SAT/koaia/engines"

    readonly property string enginesRoot:
        enginesRootField.text !== "" ? enginesRootField.text : defaultEnginesRoot

    readonly property var grouped: BuildPresets.byFamily()

    function urlToLocalPath(u) {
        var s = "" + u
        if (s.indexOf("file://") === 0) s = s.substring("file://".length)
        if (Qt.platform.os === "windows" && s.length > 1 && s.charAt(0) === "/")
            s = s.substring(1)
        return decodeURIComponent(s)
    }

    function bundleDir(preset) {
        return enginesRoot.replace(/[\/\\]+$/, "") + "/" + preset.slug
    }

    // A preset is "built" when its bundle folder carries the sidecar that
    // train-lora.py writes last. Checking bundle.json rather than *.engine also
    // rules out a half-finished build that was interrupted mid-export.
    function isBuilt(preset) {
        return Util.fileExists(bundleDir(preset) + "/bundle.json")
    }

    function builtCount() {
        var n = 0
        for (var i = 0; i < BuildPresets.presets.length; i++)
            if (isBuilt(BuildPresets.presets[i])) n++
        return n
    }

    onVisibleChanged: if (visible) refreshKey++

    Component.onCompleted: {
        enginesRootField.text = presetSettings.enginesRoot
        if (enginesRootField.text === "")
            enginesRootField.text = defaultEnginesRoot
        refreshKey++
    }

    FolderDialog {
        id: enginesRootDialog
        title: "Select Engines Folder"
        onAccepted: {
            if (!selectedFolder) return
            enginesRootField.text = urlToLocalPath(selectedFolder)
            presetView.refreshKey++
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            x: appStyle.padding
            width: parent.width - 2 * appStyle.padding
            spacing: appStyle.spacing * 0.75

            Label {
                text: "Build Presets"
                font.bold: true
                font.pixelSize: appStyle.fontSizeTitle
                color: appStyle.textColor
                Layout.topMargin: appStyle.padding
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: appStyle.textColorSecondary
                font.pixelSize: appStyle.fontSizeSmall
                text: "Each preset is one validated train-lora.py invocation that produces a "
                    + "TensorRT engine bundle. Click one to fill in the builder, then press "
                    + "Build. Batch size and image geometry are baked into the engine, which "
                    + "is why several presets differ only in those."
            }

            Label {
                text: "Engines Folder"
                font.bold: true
                color: appStyle.textColor
                font.pixelSize: appStyle.fontSizeBody
                Layout.topMargin: appStyle.spacing
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: appStyle.spacing

                TextField {
                    id: enginesRootField
                    Layout.fillWidth: true
                    font.pixelSize: appStyle.fontSizeBody
                    placeholderText: presetView.defaultEnginesRoot
                    onTextChanged: {
                        presetSettings.enginesRoot = text
                        presetView.refreshKey++
                    }
                }

                Button {
                    text: "Browse"
                    font.pixelSize: appStyle.fontSizeBody
                    onClicked: enginesRootDialog.open()
                }

                Button {
                    text: "Rescan"
                    font.pixelSize: appStyle.fontSizeBody
                    onClicked: presetView.refreshKey++
                }
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pixelSize: appStyle.fontSizeSmall
                color: appStyle.textColorSecondary
                text: {
                    presetView.refreshKey
                    return presetView.builtCount() + " / " + BuildPresets.presets.length
                        + " bundles built under this folder. Each preset builds into its own "
                        + "subfolder, so they do not overwrite each other."
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: appStyle.spacing * 0.5
                Layout.preferredHeight: 1
                color: appStyle.separatorColor
            }

            Repeater {
                model: presetView.grouped.order

                ColumnLayout {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.topMargin: appStyle.spacing
                    spacing: appStyle.spacing * 0.5

                    Label {
                        text: modelData
                        font.bold: true
                        font.pixelSize: appStyle.fontSizeBody
                        color: appStyle.textColorSecondary
                    }

                    Repeater {
                        model: presetView.grouped.groups[modelData] || []

                        Rectangle {
                            id: card
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: cardColumn.implicitHeight + 2 * appStyle.spacing
                            radius: appStyle.borderRadius
                            color: cardMouse.containsMouse ? appStyle.backgroundColorTertiary
                                                           : appStyle.backgroundColorSecondary
                            border.width: 1
                            border.color: cardMouse.containsMouse ? appStyle.primaryColor
                                                                  : appStyle.borderColor

                            readonly property bool built: {
                                presetView.refreshKey
                                return presetView.isBuilt(card.modelData)
                            }

                            // The packaged train-lora.py can be older than this
                            // catalogue; say so on the card rather than letting the
                            // build fail on an unknown flag.
                            readonly property var unsupported:
                                presetView.builder
                                ? presetView.builder.unsupportedFlags(card.modelData) : []

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: appStyle.spacing
                                spacing: appStyle.spacing

                                Rectangle {
                                    Layout.preferredWidth: 9
                                    Layout.preferredHeight: 9
                                    radius: 4.5
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 4
                                    color: card.built ? appStyle.buttonBgActive : appStyle.borderColor
                                }

                                ColumnLayout {
                                    id: cardColumn
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: card.modelData.label
                                        elide: Text.ElideRight
                                        font.pixelSize: appStyle.fontSizeBody
                                        color: card.built ? appStyle.textColor
                                                          : appStyle.textColorSecondary
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        font.pixelSize: appStyle.fontSizeSmall
                                        color: appStyle.textColorSecondary
                                        text: {
                                            var p = card.modelData
                                            var s = p.model + "  -  " + p.optWidth + "x" + p.optHeight
                                                  + ", batch " + p.maxBatch
                                            if (p.steps) s += ", " + p.steps + " step"
                                            return s
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        wrapMode: Text.WordWrap
                                        font.pixelSize: appStyle.fontSizeSmall
                                        color: appStyle.textColorSecondary
                                        text: card.modelData.note || ""
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        wrapMode: Text.WordWrap
                                        font.pixelSize: appStyle.fontSizeSmall
                                        color: appStyle.errorColor
                                        text: {
                                            if (card.unsupported.length > 0)
                                                return "The packaged engine builder lacks "
                                                     + card.unsupported.join(", ")
                                            return card.modelData.requires
                                                 ? "Needs " + card.modelData.requires : ""
                                        }
                                    }
                                }

                                Label {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: card.unsupported.length > 0 ? "unavailable"
                                        : card.built ? "built" : "not built"
                                    font.pixelSize: appStyle.fontSizeSmall
                                    color: card.built ? appStyle.buttonBgActive
                                                      : appStyle.textColorSecondary
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!presetView.builder)
                                        return
                                    presetView.builder.applyBuildPreset(
                                        card.modelData, presetView.bundleDir(card.modelData))
                                    mainWindow.currentViewIndex = mainWindow.modelViewIndex
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: appStyle.padding }
        }
    }
}
