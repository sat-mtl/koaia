import QtCore
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import Score.UI as UI
import koaia

Pane {
    id: modelView
    background: Rectangle {
        color: appStyle.backgroundColor
    }

    // Library paths from Settings
    Settings {
        id: librarySettings
        category: "Library"
    }

    Settings {
        id: buildSettings
        category: "BuildState"
        property string lastStatus: "idle"
        property bool lastLogExpanded: false
    }

    readonly property bool isWin32: Qt.platform.os === "windows"

    // Computed paths based on Library root
    readonly property string libraryRoot: librarySettings.value("RootPath", "")

    readonly property string uvPath: libraryRoot + "/packages/python-uv/uv"
    readonly property string scriptPath: libraryRoot + "/packages/librediffusion/train-lora.py"
    readonly property string scriptDir: libraryRoot + "/packages/librediffusion"

    property bool isSyncing: syncProcess.running
    property bool isBuilding: syncProcess.running || buildProcess.running

    property string buildStatus: "idle"   // "idle" | "running" | "success" | "failed"
    property real buildProgressValue: 0
    property bool logExpanded: false
    property bool _syncStarted: false
    property bool _buildStarted: false

    // Persist state changes
    onBuildStatusChanged: buildSettings.lastStatus = buildStatus
    onLogExpandedChanged: buildSettings.lastLogExpanded = logExpanded

    NumberAnimation {
        id: progressAnimation
        target: modelView
        property: "buildProgressValue"
        from: 0
        to: 80
        duration: 13 * 60 * 1000
        easing.type: Easing.Linear
    }

    Component.onCompleted: {
        logExpanded = buildSettings.lastLogExpanded
        // "running" means app was killed mid-build — treat as interrupted
        var last = buildSettings.lastStatus
        buildStatus = (last === "running") ? "idle" : last
        buildProgressValue = (buildStatus === "success") ? 100 : 0
        loadLog()
    }

    function logFilePath() {
        var base = StandardPaths.writableLocation(StandardPaths.AppConfigLocation)
        var clean = base.replace(/\\/g, '/')   // normalize Windows backslashes
        return (isWin32 ? "file:///" : "file://") + clean + "/build.log"
    }

    function saveLog() {
        var xhr = new XMLHttpRequest()
        xhr.open("PUT", logFilePath())
        xhr.send(logTextArea.text)
    }

    function loadLog() {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 0 && xhr.responseText)
                logTextArea.text = xhr.responseText
        }
        xhr.open("GET", logFilePath())
        xhr.send()
    }

    function log(message) {
        var time = new Date();
        var timestamp = time.getHours() + ":" +
                       (time.getMinutes() < 10 ? "0" : "") + time.getMinutes() + ":" +
                       (time.getSeconds() < 10 ? "0" : "") + time.getSeconds();
        logTextArea.append("[" + timestamp + "] " + message);
        console.log(message);
    }

    // Sync process (runs uv sync first)
    UI.Process {
        id: syncProcess
        program: uvPath
        arguments: isWin32 ? ["sync", "--cache-dir", "c:\\uv"] : ["sync"]

        onLineReceived: (line, isError) => {
            if (isError) {
                log("[sync stderr] " + line);
            } else {
                log("[sync] " + line);
            }
        }

        onRunningChanged: {
            if (running) {
                _syncStarted = true
            } else if (_syncStarted) {
                _syncStarted = false
                if (exitCode === 0) {
                    log("[sync] Environment ready");
                    log("----------------------------------------");
                    runBuildProcess();
                } else {
                    progressAnimation.stop()
                    buildStatus = "failed"
                    log("[sync] Failed with exit code: " + exitCode);
                    log("----------------------------------------");
                    saveLog()
                }
            }
        }

        onProcessErrorChanged: {
            if (processError === UI.Process.FailedToStart) {
                log("[Error] Failed to start uv sync at: " + uvPath);
            }
        }
    }

    // Build process
    UI.Process {
        id: buildProcess
        program: uvPath

        onLineReceived: (line, isError) => {
            if (isError) {
                log("[stderr] " + line);
            } else {
                log(line);
            }
        }

        onRunningChanged: {
            if (running) {
                _buildStarted = true
            } else if (_buildStarted) {
                _buildStarted = false
                progressAnimation.stop()
                log("\n----------------------------------------");
                log("[Build process exited with code: " + exitCode + "]");
                if (exitCode === 0) {
                    buildProgressValue = 100
                    refreshEngines()
                    engineCheckTimer.start()
                } else {
                    buildStatus = "failed"
                    saveLog()
                }
            }
        }

        onProcessErrorChanged: {
            if (processError === UI.Process.FailedToStart) {
                log("[Error] Failed to start build process at: " + uvPath);
            } else if (processError === UI.Process.Crashed) {
                log("[Error] Build process crashed");
            }
        }
    }

    // LoRA list model
    ListModel {
        id: loraListModel
    }

    // Watches the output folder for built engine files
    FolderListModel {
        id: engineModel
        nameFilters: ["*.engine", "*.onnx"]
        showDirs: false
        showHidden: false
        folder: {
            if (!outputPathField || outputPathField.text === "") return ""
            var p = outputPathField.text.replace(/\\/g, '/')
            return (isWin32 ? "file:///" : "file://") + p
        }
    }

    function refreshEngines() {
        var f = engineModel.folder
        engineModel.folder = ""
        engineModel.folder = f
    }

    // After exit code 0, wait briefly for FolderListModel to scan output folder.
    // Only declare success if .engine files are actually present.
    Timer {
        id: engineCheckTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (engineModel.count > 0) {
                buildStatus = "success"
                log("[Build complete] " + engineModel.count + " engine file(s) found.")
            } else {
                buildStatus = "failed"
                log("[Warning] Build process exited 0 but no .engine files found in: " + outputPathField.text)
            }
            saveLog()
        }
    }

    // Section component (reused from MainView pattern)
    component Section: ColumnLayout {
        property string title: ""
        property string description: ""
        default property alias content: body.data
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: appStyle.spacing
            Layout.bottomMargin: 6
            spacing: 8

            CustomLabel {
                Layout.fillWidth: true
                text: title
                font.pixelSize: appStyle.fontSizeSubtitle
                font.bold: true

                ToolTip.visible: description !== "" && headerMouseArea.containsMouse
                ToolTip.text: description
                ToolTip.delay: 500

                MouseArea {
                    id: headerMouseArea
                    anchors.fill: parent
                    hoverEnabled: description !== ""
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: appStyle.borderColor
            opacity: 0.8
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 8
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: appStyle.padding
        spacing: appStyle.spacing

        CustomLabel {
            text: "Model Builder"
            font.bold: true
            font.pixelSize: appStyle.fontSizeTitle
        }

        CustomLabel {
            text: "Build TensorRT engines from Stable Diffusion models.\nNote that this is a long process: roughly fifteen minutes for a given model."
            font.pixelSize: appStyle.fontSizeBody
            color: appStyle.textColorSecondary
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: appStyle.spacing

                Section {
                    title: "Model Configuration"
                    description: "Configure the base model and output location"

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Model Type"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        ComboBox {
                            id: modelTypeCombo
                            Layout.fillWidth: true
                            model: ["SD 1.5 / Turbo", "SDXL"]
                            currentIndex: 0
                            font.pixelSize: appStyle.fontSizeBody
                            property string modelTypeArg: currentIndex === 0 ? "sd15" : "sdxl"
                            onCurrentIndexChanged: {
                                modelSourceField.text = currentIndex === 0
                                    ? "SimianLuo/LCM_Dreamshaper_v7"
                                    : "stabilityai/stable-diffusion-xl-base-1.0"
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Model Source"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        TextField {
                            id: modelSourceField
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            text: "SimianLuo/LCM_Dreamshaper_v7"
                            placeholderText: "HuggingFace model ID or local path"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Output Path"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                            color: outputPathField.text !== "" ? palette.windowText : "red"
                        }
                        TextField {
                            id: outputPathField
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            text: ""
                            placeholderText: "Path to save engine files"
                        }
                        Button {
                            text: "Browse"
                            font.pixelSize: appStyle.fontSizeBody
                            onClicked: outputFolderDialog.open()
                        }
                    }

                    FolderDialog {
                        id: outputFolderDialog
                        title: "Select Output Folder"
                        onAccepted: {
                            if (!selectedFolder)
                                return;
                            var folderPath = new URL(selectedFolder).pathname.substr(isWin32 ? 1 : 0);
                            outputPathField.text = folderPath;
                        }
                    }
                }

                Section {
                    title: "LoRA Files"
                    description: "Optional LoRA weights to merge into the model (format: path or path:weight)"

                    Repeater {
                        model: loraListModel

                        RowLayout {
                            Layout.fillWidth: true
                            required property int index
                            required property string path
                            required property real weight

                            TextField {
                                Layout.fillWidth: true
                                font.pixelSize: appStyle.fontSizeBody
                                text: path
                                placeholderText: "/path/to/lora.safetensors"
                                onTextChanged: loraListModel.setProperty(index, "path", text)
                            }
                            Button {
                                text: "..."
                                font.pixelSize: appStyle.fontSizeBody
                                implicitWidth: 40
                                onClicked: {
                                    loraFileDialog.currentLoraIndex = index;
                                    loraFileDialog.open();
                                }
                            }
                            Label {
                                text: "Weight"
                                font.pixelSize: appStyle.fontSizeSmall
                            }
                            SpinBox {
                                id: weightSpinBox
                                editable: true
                                Layout.minimumWidth: 150
                                implicitWidth: 150
                                from: 0
                                to: 200
                                value: weight * 100
                                stepSize: 5
                                font.pixelSize: appStyle.fontSizeSmall
                                property real realValue: value / 100.0
                                textFromValue: function (value, locale) {
                                    return (value / 100.0).toFixed(2);
                                }
                                valueFromText: function (text, locale) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                onValueChanged: loraListModel.setProperty(index, "weight", realValue)
                            }
                            Button {
                                text: "X"
                                font.pixelSize: appStyle.fontSizeBody
                                implicitWidth: 40
                                onClicked: loraListModel.remove(index)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: "+ Add LoRA"
                            font.pixelSize: appStyle.fontSizeBody
                            onClicked: loraListModel.append({
                                "path": "",
                                "weight": 1.0
                            })
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Label {
                            text: "Global Scale"
                            font.pixelSize: appStyle.fontSizeBody
                            visible: loraListModel.count > 0
                        }
                        SpinBox {
                            id: loraScaleSpinBox
                            editable: true
                            visible: loraListModel.count > 0
                            Layout.minimumWidth: 150
                            implicitWidth: 150
                            from: 0
                            to: 500
                            value: 250
                            stepSize: 10
                            font.pixelSize: appStyle.fontSizeSmall
                            property real realValue: value / 100.0
                            textFromValue: function (value, locale) {
                                return (value / 100.0).toFixed(2);
                            }
                            valueFromText: function (text, locale) {
                                return Math.round(parseFloat(text) * 100);
                            }
                        }
                    }

                    FileDialog {
                        id: loraFileDialog
                        title: "Select LoRA File"
                        nameFilters: ["SafeTensors Files (*.safetensors)", "All Files (*)"]
                        property int currentLoraIndex: -1
                        onAccepted: {
                            if (!selectedFile || currentLoraIndex < 0)
                                return;
                            var filePath = new URL(selectedFile).pathname.substr(isWin32 ? 1 : 0);
                            loraListModel.setProperty(currentLoraIndex, "path", filePath);
                        }
                    }

                    Label {
                        visible: loraListModel.count === 0
                        text: "No LoRA files added"
                        font.pixelSize: appStyle.fontSizeSmall
                        color: appStyle.textColorSecondary
                    }
                }

                Section {
                    title: "Build Parameters"
                    description: "TensorRT engine build configuration"

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "Batch Size"
                                font.pixelSize: appStyle.fontSizeBody
                                font.bold: true
                            }
                            RowLayout {
                                Label {
                                    text: "Min"
                                    font.pixelSize: appStyle.fontSizeBody
                                    Layout.preferredWidth: 40
                                }
                                SpinBox {
                                    id: minBatchSpinBox
                                    editable: true
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 16
                                    value: 1
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                            RowLayout {
                                Label {
                                    text: "Opt"
                                    font.pixelSize: appStyle.fontSizeBody
                                    Layout.preferredWidth: 40
                                }
                                SpinBox {
                                    id: optBatchSpinBox
                                    editable: true
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 16
                                    value: 2
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                            RowLayout {
                                Label {
                                    text: "Max"
                                    font.pixelSize: appStyle.fontSizeBody
                                    Layout.preferredWidth: 40
                                }
                                SpinBox {
                                    id: maxBatchSpinBox
                                    editable: true
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 16
                                    value: 2
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "Resolution"
                                font.pixelSize: appStyle.fontSizeBody
                                font.bold: true
                            }
                            RowLayout {
                                Label {
                                    text: "Min"
                                    font.pixelSize: appStyle.fontSizeBody
                                    Layout.preferredWidth: 40
                                }
                                SpinBox {
                                    id: minResolutionSpinBox
                                    editable: true
                                    Layout.fillWidth: true
                                    from: 256
                                    to: 2048
                                    value: 1024
                                    stepSize: 64
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                            RowLayout {
                                Label {
                                    text: "Max"
                                    font.pixelSize: appStyle.fontSizeBody
                                    Layout.preferredWidth: 40
                                }
                                SpinBox {
                                    id: maxResolutionSpinBox
                                    editable: true
                                    Layout.fillWidth: true
                                    from: 256
                                    to: 2048
                                    value: 1024
                                    stepSize: 64
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "Optimal Size"
                                font.pixelSize: appStyle.fontSizeBody
                                font.bold: true
                            }
                            RowLayout {
                                Label {
                                    text: "Width"
                                    font.pixelSize: appStyle.fontSizeBody
                                    Layout.preferredWidth: 40
                                }
                                SpinBox {
                                    id: optWidthSpinBox
                                    editable: true
                                    Layout.fillWidth: true
                                    from: 256
                                    to: 2048
                                    value: 1024
                                    stepSize: 64
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                            RowLayout {
                                Label {
                                    text: "Height"
                                    font.pixelSize: appStyle.fontSizeBody
                                    Layout.preferredWidth: 40
                                }
                                SpinBox {
                                    id: optHeightSpinBox
                                    editable: true
                                    Layout.fillWidth: true
                                    from: 256
                                    to: 2048
                                    value: 1024
                                    stepSize: 64
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                        }
                    }

                    Label {
                        Layout.topMargin: 4
                        text: {
                            var errors = [];
                            if (maxBatchSpinBox.value < minBatchSpinBox.value)
                                errors.push("Max batch must be >= min batch");
                            if (optBatchSpinBox.value < minBatchSpinBox.value || optBatchSpinBox.value > maxBatchSpinBox.value)
                                errors.push("Opt batch must be between min and max");
                            if (maxResolutionSpinBox.value < minResolutionSpinBox.value)
                                errors.push("Max resolution must be >= min resolution");
                            return errors.join("; ");
                        }
                        font.pixelSize: appStyle.fontSizeSmall
                        color: "red"
                        visible: text !== ""
                    }
                }

            }
        }

        // Build button — always visible, anchored below config
        RowLayout {
            Layout.fillWidth: true
            spacing: appStyle.spacing

            Button {
                Layout.fillWidth: true
                text: isBuilding ? "Stop Build" : "Build Engine"
                font.pixelSize: appStyle.fontSizeBody
                font.bold: true
                highlighted: !isBuilding
                onClicked: isBuilding ? stopBuild() : startBuild()
            }
        }

        // Progress bar — thin, inline status, only visible when active
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: buildStatus !== "idle"

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: appStyle.backgroundColorSecondary

                Rectangle {
                    width: buildProgressValue / 100 * parent.width
                    height: parent.height
                    radius: 2
                    color: buildStatus === "success" ? "#4CAF50"
                         : buildStatus === "failed"  ? "#f44336"
                         : appStyle.primaryColor
                    Behavior on color { ColorAnimation { duration: 400 } }
                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                }
            }

            Label {
                text: buildStatus === "running" ? Math.round(buildProgressValue) + "%"
                    : buildStatus === "success" ? "Done"
                    : "Failed"
                font.pixelSize: appStyle.fontSizeSmall
                color: buildStatus === "success" ? "#4CAF50"
                     : buildStatus === "failed"  ? "#f44336"
                     : appStyle.textColorSecondary
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }
        }

        // Built engines — visible once an output path is set
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: outputPathField && outputPathField.text !== ""

            RowLayout {
                Layout.fillWidth: true
                spacing: appStyle.spacing

                CustomLabel {
                    text: "Built Engines"
                    font.pixelSize: appStyle.fontSizeSmall
                    color: appStyle.textColorSecondary
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Refresh"
                    font.pixelSize: appStyle.fontSizeSmall
                    onClicked: refreshEngines()
                }
                Button {
                    text: "Open Folder"
                    font.pixelSize: appStyle.fontSizeSmall
                    onClicked: Qt.openUrlExternally(engineModel.folder)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: appStyle.borderColor
                opacity: 0.5
            }

            Repeater {
                model: engineModel

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: appStyle.primaryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        Layout.fillWidth: true
                        text: fileName
                        font.pixelSize: appStyle.fontSizeSmall
                        color: appStyle.textColor
                        elide: Text.ElideMiddle
                    }
                }
            }

            Label {
                visible: engineModel.count === 0
                text: "No engines found"
                font.pixelSize: appStyle.fontSizeSmall
                color: appStyle.textColorSecondary
                font.italic: true
            }
        }

        // Collapsible output — closed by default, auto-opens on build start
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: logExpanded ? "▾" : "▸"
                    font.pixelSize: appStyle.fontSizeSmall
                    color: appStyle.textColorSecondary
                }
                CustomLabel {
                    text: "Output"
                    font.pixelSize: appStyle.fontSizeSmall
                    color: appStyle.textColorSecondary
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Clear"
                    font.pixelSize: appStyle.fontSizeSmall
                    visible: logExpanded
                    onClicked: logTextArea.text = ""
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: logExpanded = !logExpanded
                    cursorShape: Qt.PointingHandCursor
                }
            }

            ScrollView {
                visible: logExpanded
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                clip: true

                TextArea {
                    id: logTextArea
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    font.family: appStyle.fontFamily
                    font.pixelSize: appStyle.fontSizeBody
                    color: appStyle.textColor
                }
            }
        }

    }

    // Start build: first sync, then run
    function startBuild() {
        var errors = [];
        if (libraryRoot === "") errors.push("Library path not configured");
        if (modelSourceField.text === "") errors.push("Model source path is empty");
        if (outputPathField.text === "") errors.push("Output path is empty");
        if (maxBatchSpinBox.value < minBatchSpinBox.value) errors.push("Max batch must be >= min batch");
        if (optBatchSpinBox.value < minBatchSpinBox.value || optBatchSpinBox.value > maxBatchSpinBox.value) errors.push("Opt batch must be between min and max batch");
        if (maxResolutionSpinBox.value < minResolutionSpinBox.value) errors.push("Max resolution must be >= min resolution");
        if (errors.length > 0) {
            for (var i = 0; i < errors.length; i++)
                log("[Error] " + errors[i]);
            return;
        }

        buildStatus = "running"
        buildProgressValue = 0
        logExpanded = true
        progressAnimation.restart()

        syncProcess.clearOutput();
        buildProcess.clearOutput();

        log("[Syncing environment in " + scriptDir + "]");
        log("$ " + uvPath + " sync");
        log("----------------------------------------");

        // Set working directory and start sync
        syncProcess.workingDirectory = scriptDir;
        buildProcess.workingDirectory = scriptDir;
        syncProcess.start();
    }

    // Called after successful sync
    function runBuildProcess() {
        // Build argument list with argparse-style flags
        var args = [];
        if (isWin32)
            args.push("--cache-dir", "c:\\uv");
        args.push("run", "train-lora.py", "--type", modelTypeCombo.modelTypeArg, "--model", modelSourceField.text, "--output", outputPathField.text, "--min-batch", minBatchSpinBox.value.toString(), "--max-batch", maxBatchSpinBox.value.toString(), "--opt-batch", optBatchSpinBox.value.toString(), "--min-resolution", minResolutionSpinBox.value.toString(), "--max-resolution", maxResolutionSpinBox.value.toString(), "--opt-width", optWidthSpinBox.value.toString(), "--opt-height", optHeightSpinBox.value.toString());

        // Add LoRAs with weights
        for (var i = 0; i < loraListModel.count; i++) {
            var lora = loraListModel.get(i);
            if (lora.path !== "") {
                var loraArg = lora.path;
                if (lora.weight !== 1.0) {
                    loraArg += ":" + lora.weight.toFixed(2);
                }
                args.push("--lora");
                args.push(loraArg);
            }
        }

        // Add global LoRA scale if LoRAs are present
        if (loraListModel.count > 0) {
            args.push("--lora-scale");
            args.push(loraScaleSpinBox.realValue.toFixed(2));
        }

        // Log the command
        var cmdLine = uvPath + " " + args.join(" ");
        log("[Starting build]");
        log("$ cd " + scriptDir + " && " + cmdLine);
        log("----------------------------------------");

        // Set working directory, arguments and start
        buildProcess.workingDirectory = scriptDir;
        buildProcess.arguments = args;
        buildProcess.start();
    }

    function stopBuild() {
        progressAnimation.stop()
        engineCheckTimer.stop()
        _syncStarted = false
        _buildStarted = false
        buildStatus = "idle"
        buildProgressValue = 0
        log("\n[Stopping...]");
        if (syncProcess.running) {
            syncProcess.stop();
        }
        if (buildProcess.running) {
            buildProcess.stop();
        }
    }
}
