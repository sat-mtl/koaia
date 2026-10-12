// SPDX-License-Identifier: AGPL-3.0-or-later
// © Société des arts technologiques
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "../Scripts/InputBackends.js" as Backends

// Multi-backend video-input picker -- PURE PRESENTATION.
//
// Vendored from qmlcomponents' io/InputSourceSelector.qml (the module livepose,
// DomeportPro and SPM share), with Theme swapped for koaia's appStyle and the
// Custom* widgets swapped for the stock controls koaia's palette already themes.
// koaia does not use qmlcomponents and adopting it would mean running two theme
// systems side by side, so the 200 lines are copied instead; InputBackends.js
// next to this file is byte-identical to the module's, which is the part that
// actually changes when a new protocol appears.
//
// Two upstream defects are fixed here rather than reproduced, because both
// consumers already carry a workaround for them:
//   * a path edit no longer re-emits backendSelected (DomeportController.js
//     reorders its drag-and-drop handling to survive that);
//   * the source combo follows currentSource when the host sets it
//     programmatically (livepose papers over it with a status line).
//
// This widget performs NO Score.* calls. The host owns the device lifecycle --
// see Scripts/InputDevices.js.
ColumnLayout {
    id: selector

    // ---- Inputs from the host ----
    property string platformOs: Qt.platform.os
    property var allowedBackends: ["Camera", "Video file"]
    property var sources: []
    property string statusText: ""

    // ---- Derived / current state ----
    property var backends: Backends.filterBackends(allowedBackends, platformOs)
    property string currentBackend: backends.length > 0 ? backends[0] : ""
    property string currentSource: ""
    property string videoFilePath: ""

    readonly property bool deviceBackend: Backends.isDevice(currentBackend)
    readonly property bool videoBackend: Backends.isVideo(currentBackend)
    readonly property bool typableSource: Backends.isTypable(currentBackend)

    // ---- Signals to the host ----
    signal backendSelected(string name)
    signal sourceSelected(string name)
    signal videoFileSelected(string path)
    signal refreshRequested

    function descriptor(name) { return Backends.descriptor(name) }

    onCurrentBackendChanged: syncBackendCombo()
    Component.onCompleted: syncBackendCombo()
    function syncBackendCombo() {
        var idx = backends.indexOf(currentBackend)
        if (idx >= 0 && idx !== backendCombo.currentIndex)
            backendCombo.currentIndex = idx
    }

    spacing: appStyle.spacing

    RowLayout {
        Layout.fillWidth: true
        Label {
            text: "Source"
            Layout.preferredWidth: 100
            font.pixelSize: appStyle.fontSizeBody
        }
        ComboBox {
            id: backendCombo
            Layout.fillWidth: true
            font.pixelSize: appStyle.fontSizeBody
            model: selector.backends
            onActivated: index => {
                selector.currentBackend = selector.backends[index]
                selector.currentSource = ""
                selector.backendSelected(selector.currentBackend)
            }
        }
    }

    // ---- Device source row (Camera / NDI / Spout / Syphon) ----
    RowLayout {
        Layout.fillWidth: true
        visible: selector.deviceBackend
        spacing: appStyle.spacing

        Label {
            text: "Device"
            Layout.preferredWidth: 100
            font.pixelSize: appStyle.fontSizeBody
        }

        ComboBox {
            id: pickCombo
            Layout.fillWidth: true
            font.pixelSize: appStyle.fontSizeBody
            // NDI/Spout/Syphon sources can be named before they appear, so those
            // backends get a combo you can also type into.
            editable: selector.typableSource
            model: selector.sources
            currentIndex: selector.sources.indexOf(selector.currentSource)
            // Nothing is selected until the user picks, so currentIndex is -1 and
            // a stock ComboBox then draws an empty box however full its model is.
            // That reads as "no devices found" and was reported as exactly that.
            displayText: currentIndex >= 0 ? currentText
                       : selector.sources.length > 0
                         ? qsTr("%1 available — click to choose").arg(selector.sources.length)
                         : qsTr("No device found yet")
            onActivated: index => {
                selector.currentSource = selector.sources[index] || ""
                if (selector.currentSource !== "")
                    selector.sourceSelected(selector.currentSource)
            }
            onAccepted: {
                if (!editable || editText === "")
                    return
                selector.currentSource = editText
                selector.sourceSelected(editText)
            }
        }

        Button {
            text: "Refresh"
            font.pixelSize: appStyle.fontSizeBody
            onClicked: selector.refreshRequested()
        }
    }

    Label {
        Layout.fillWidth: true
        visible: selector.deviceBackend && selector.statusText !== ""
        text: selector.statusText
        wrapMode: Text.WordWrap
        color: appStyle.textColorSecondary
        font.pixelSize: appStyle.fontSizeSmall
    }

    // ---- Video-file row ----
    RowLayout {
        Layout.fillWidth: true
        visible: selector.videoBackend
        spacing: appStyle.spacing

        Label {
            text: "File"
            Layout.preferredWidth: 100
            font.pixelSize: appStyle.fontSizeBody
        }

        TextField {
            id: videoPathField
            Layout.fillWidth: true
            font.pixelSize: appStyle.fontSizeBody
            placeholderText: "/path/to/video.mp4"
            text: selector.videoFilePath
            onTextChanged: {
                selector.videoFilePath = text
                selector.videoFileSelected(text)
            }
        }

        Button {
            text: "Browse"
            font.pixelSize: appStyle.fontSizeBody
            onClicked: videoFileDialog.open()
        }
    }

    FileDialog {
        id: videoFileDialog
        title: "Select Video File"
        nameFilters: ["Video Files (*.mp4 *.avi *.mov *.mkv *.webm *.flv)", "All Files (*)"]
        onAccepted: {
            if (!selectedFile)
                return
            videoPathField.text = new URL(selectedFile).pathname.substr(
                Qt.platform.os === "windows" ? 1 : 0)
        }
    }
}
