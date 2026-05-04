import QtCore
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
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

    readonly property bool isWin32: Qt.platform.os === "windows"

    // Computed paths based on Library root
    readonly property string libraryRoot: librarySettings.value("RootPath", "")

    readonly property string uvPath: libraryRoot + "/packages/python-uv/uv"
    readonly property string scriptPath: libraryRoot + "/packages/librediffusion/train-loras.py"
    readonly property string scriptDir: libraryRoot + "/packages/librediffusion"

    property bool isSyncing: syncProcess.running
    property bool isBuilding: syncProcess.running || buildProcess.running

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
            if (!running) {
                if (exitCode === 0) {
                    log("[sync] Environment ready");
                    log("----------------------------------------");
                    // Now start the actual build
                    runBuildProcess();
                } else {
                    log("[sync] Failed with exit code: " + exitCode);
                    log("----------------------------------------");
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
            if (!running) {
                log("\n----------------------------------------");
                log("[Build finished with exit code: " + exitCode + "]");
                if (exitCode === 0) {
                    var folderPath = outputPathField.text;
                    if (isWin32) {
                        folderPath = folderPath.replace(/\\/g, '/');
                    }

                    Qt.openUrlExternally(Qt.resolvedUrl(folderPath));
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
            Layout.preferredHeight: contentHeight
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

                // Build button
                Button {
                    Layout.fillWidth: true
                    Layout.topMargin: appStyle.spacing
                    text: isBuilding ? "Stop Build" : "Build Engine"
                    font.pixelSize: appStyle.fontSizeBody
                    font.bold: true
                    highlighted: !isBuilding
                    onClicked: isBuilding ? stopBuild() : startBuild()
                }

                Item {
                    height: appStyle.padding
                }

            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: appStyle.spacing

            CustomLabel {
                text: "Build Output"
                font.pixelSize: appStyle.fontSizeSmall
                color: appStyle.textColorSecondary
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Clear Log"
                font.pixelSize: appStyle.fontSizeSmall
                onClicked: logTextArea.text = ""
            }

            Button {
                text: "Test Log"
                font.pixelSize: appStyle.fontSizeSmall
                onClicked: log("Test log message at " + new Date().toLocaleTimeString())
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

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
        log("\n[Stopping...]");
        if (syncProcess.running) {
            syncProcess.stop();
        }
        if (buildProcess.running) {
            buildProcess.stop();
        }
    }
}
