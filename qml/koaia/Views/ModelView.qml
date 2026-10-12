import QtCore
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import Score.UI as UI
import koaia
import "../Scripts/BuildPresets.js" as BuildPresets

Pane {
    id: modelView
    background: Rectangle {
        color: appStyle.backgroundColor
    }

    Settings {
        id: buildSettings
        category: "BuildState"
        property bool lastLogExpanded: false
        property string uvCacheDir: ""
        property string modelCacheDir: ""
    }

    readonly property bool isWin32: Qt.platform.os === "windows"

    // The engine builder ships inside the package, so nothing here depends on
    // score's package manager or on a configured library root. create-app.sh
    // copies the contents of koaia/score/ next to the QML tree, giving
    // <root>/engine-builder and <root>/qml; this file sits three levels down
    // in the latter. Strip the file:// scheme -- Process.program takes a path.
    readonly property string appRoot: {
        var u = Qt.resolvedUrl("../../..").toString()
        if (u.startsWith("file://")) u = u.substring(7)
        // Windows resolves to file:///C:/..., so dropping the scheme leaves a
        // leading slash in front of the drive letter that Process would reject.
        if (/^\/[A-Za-z]:/.test(u)) u = u.substring(1)
        return u.replace(/\/$/, "")
    }

    readonly property string scriptDir: appRoot + "/engine-builder"
    readonly property string uvPath: scriptDir + (isWin32 ? "/uv.exe" : "/uv")
    readonly property string scriptPath: scriptDir + "/train-lora.py"

    // uv is NOT run in scriptDir: inside the Linux AppImage that path is a
    // read-only squashfs mount and `uv sync` dies with
    //   error: failed to create directory `.../engine-builder/.venv`: Read-only file system
    // On Windows the package directory may equally be somewhere the user cannot
    // write. So the venv, both caches and the env file live in a per-user
    // workspace, and only pyproject.toml + uv.lock are copied there.
    //
    // This works because the project declares no [build-system] and no local path
    // dependencies -- uv installs dependencies only -- and train-lora.py puts its
    // own `src` on sys.path from __file__ (train-lora.py:33-35), so it can be run
    // by absolute path from anywhere.
    readonly property string workspaceDir:
        urlToLocalPath(StandardPaths.writableLocation(StandardPaths.AppDataLocation))
        + "/engine-builder"

    // The three caches an engine build touches are distinct and only one of them
    // is uv's:
    //   * uv's wheel cache (--cache-dir) -- ~11 GB of torch/TensorRT wheels.
    //     Must sit on the same volume as the venv or uv cannot hardlink out of it
    //     and copies every file instead, costing the 11 GB twice.
    //   * the HuggingFace snapshot cache (HF_HOME) -- the model weights, GBs per
    //     model. train-lora.py never takes a flag for it, only the env var.
    //   * the ONNX/engine/timing-cache triple, which lives in --output.
    readonly property string uvCacheDir:
        uvCacheField.text !== "" ? uvCacheField.text : workspaceDir + "/uv-cache"
    readonly property string modelCacheDir:
        modelCacheField.text !== "" ? modelCacheField.text : workspaceDir + "/hf-cache"

    readonly property string envFilePath: workspaceDir + "/build.env"

    function urlToLocalPath(u) {
        var s = "" + u
        if (s.indexOf("file://") === 0) s = s.substring("file://".length)
        if (isWin32 && s.length > 1 && s.charAt(0) === "/")
            s = s.substring(1)
        return decodeURIComponent(s)
    }

    // The validated train-lora.py invocations, shared with BuildPresetView. SDXS-sketch
    // is first and the default: it is the 512x512 ControlNet pipeline koaia is built
    // around. Its ControlNet has to be the model's *native* one, because the exported
    // pair has to agree on geometry -- this bundle loads as "control-aware UNet geometry
    // = 6 down residuals, factors {1,1,2,2,4,4}" against "ControlNet engine SD1.5,
    // 6 down residuals", and a ControlNet with a different count will not bind.
    // Declared on the root because a Section's children resolve names against the
    // file's root object, not against the enclosing Section instance.
    readonly property var modelPresets: BuildPresets.presets

    // The preset the visible fields were last filled from. --type, --unet,
    // --hw-compat, --klein-quality, the per-axis geometry flags and :runtime LoRAs
    // have no widget of their own, so they are carried from here.
    property var activePreset: BuildPresets.presets[0]

    // train-lora.py is staged from the 3rdparty/librediffusion pin, which can lag
    // the recipes in BuildPresets.js -- as it does today, by the two commits that
    // added --unet and --rife. An unknown flag surfaces as argparse "unrecognized
    // arguments" a minute into a run that looked like it had started, so read the
    // script once and check up front. An unreadable script blocks nothing.
    readonly property string _builderSource:
        Util.fileExists(scriptPath) ? String(Util.readFile(scriptPath)) : ""

    function builderSupports(flag) {
        return _builderSource === "" || _builderSource.indexOf('"' + flag + '"') >= 0
    }

    function unsupportedFlags(preset) {
        var need = BuildPresets.requiredFlags(preset), out = []
        for (var i = 0; i < need.length; i++)
            if (!builderSupports(need[i]))
                out.push(need[i])
        // Not every capability has a flag of its own: klein-sprint passes --lora,
        // which every builder accepts and an older one silently ignores.
        if (preset.needsBuilderSymbol && _builderSource !== ""
                && _builderSource.indexOf(preset.needsBuilderSymbol) < 0)
            out.push(preset.needsBuilderLabel || preset.needsBuilderSymbol)
        return out
    }

    property bool _applyingPreset: false

    // Applies a preset to every field, including the ones that have no widget.
    // Called by BuildPresetView and by the Preset combo. Reentrancy-guarded
    // because moving the combo calls straight back in through onCurrentIndexChanged.
    function applyBuildPreset(preset, outputDir) {
        if (_applyingPreset)
            return
        _applyingPreset = true
        activePreset = preset
        // Matched on slug, not identity: a preset handed over from BuildPresetView's
        // Repeater arrives as a converted copy, so indexOf() never finds it.
        for (var i = 0; i < BuildPresets.presets.length; i++) {
            if (BuildPresets.presets[i].slug === preset.slug) {
                if (modelTypeCombo.currentIndex !== i)
                    modelTypeCombo.currentIndex = i
                break
            }
        }
        modelSourceField.text = preset.model
        controlNetField.text = preset.controlnet || ""
        ipadapterField.text = ""
        minResolutionSpinBox.value = preset.minRes
        maxResolutionSpinBox.value = preset.maxRes
        optWidthSpinBox.value = preset.optWidth
        optHeightSpinBox.value = preset.optHeight
        minBatchSpinBox.value = preset.minBatch
        optBatchSpinBox.value = preset.optBatch
        maxBatchSpinBox.value = preset.maxBatch
        loraScaleSpinBox.value = Math.round((preset.loraScale !== undefined
                                             ? preset.loraScale : 1.0) * 100)
        loraListModel.clear()
        var ls = preset.loras || []
        for (var j = 0; j < ls.length; j++) {
            loraListModel.append({
                path: ls[j].path,
                weight: ls[j].weight !== undefined ? ls[j].weight : 1.0,
                runtime: !!ls[j].runtime
            })
        }
        if (outputDir !== undefined && outputDir !== "")
            outputPathField.text = outputDir
        _applyingPreset = false
        log("[Preset] " + preset.label + " -> " + preset.slug)
    }

    property bool isSyncing: syncProcess.running
    property bool isBuilding: syncProcess.running || buildProcess.running

    property string buildStatus: "idle"   // "idle" | "running" | "success" | "failed"
    property real buildProgressValue: 0
    property bool logExpanded: false
    property bool _syncStarted: false
    property bool _buildStarted: false

    onLogExpandedChanged: buildSettings.lastLogExpanded = logExpanded

    NumberAnimation {
        id: progressAnimation
        target: modelView
        property: "buildProgressValue"
        from: 0
        to: 80
        duration: 45 * 60 * 1000
        easing.type: Easing.Linear
    }

    Component.onCompleted: {
        logExpanded = buildSettings.lastLogExpanded
        buildStatus = "idle"
        buildProgressValue = 0
        uvCacheField.text = buildSettings.uvCacheDir
        modelCacheField.text = buildSettings.modelCacheDir
        loadLog()
    }

    function logFilePath() {
        return StandardPaths.writableLocation(StandardPaths.AppConfigLocation) + "/build.log"
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

    // UI.Process frames the child's output on '\n' alone and decodes every line
    // with QString::fromUtf8 unconditionally (QmlProcess.cpp:82-115). Measured on
    // a real sdxs-sketch build on Windows (69 KB of stderr): onnxruntime's native
    // logger writes **UTF-16LE**, so each character arrives followed by a NUL that
    // fromUtf8 keeps -- 23579 C0 bytes in that one capture. On top of it come 214
    // ANSI escapes (its colourised warnings ignore NO_COLOR) and 139 CRs, and
    // Python's newline translation ends all 1226 stdout lines in CRLF. A TextArea
    // draws C0 as replacement boxes and turns a bare CR into a paragraph break:
    // that is the mojibake in the build log.
    //
    // Order matters, and the two kinds of CR must not be confused.
    //
    // The NULs sit *inside* the escape sequences, so they go first or the CSI
    // pattern cannot match. Then the CRs, in two steps:
    //
    //   * A CR at end of line is CRLF **framing**, not content: UI.Process splits
    //     on '\n' with `left(idx)` and QProcess is not opened with QIODevice::Text,
    //     so the CR of every CRLF survives into the line. On Windows that is every
    //     single line Python writes -- 1680 of 1681 in the capture above. Drop it.
    //   * A CR in the *middle* means "redraw this line", as tqdm does, so only the
    //     last segment is the state the writer meant to leave behind.
    //
    // Collapsing those two cases into one lastIndexOf() deletes every CRLF line,
    // which is what the first version of this did.
    function sanitizeConsole(text) {
        var s = String(text).replace(/\x00/g, "")
        s = s.replace(/\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)/g, "")     // OSC ... BEL / ST
        s = s.replace(/\x1b\[[0-9;?]*[\x20-\x2f]*[\x40-\x7e]/g, "") // CSI
        s = s.replace(/\x1b[\x40-\x5a\x5c-\x5f]/g, "")              // two-byte Fe
        s = s.replace(/\r+$/, "")
        var last = s.lastIndexOf("\r")
        if (last >= 0)
            s = s.substring(last + 1)
        return s.replace(/[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]/g, "")
    }

    function log(message) {
        var time = new Date();
        var timestamp = time.getHours() + ":" +
                       (time.getMinutes() < 10 ? "0" : "") + time.getMinutes() + ":" +
                       (time.getSeconds() < 10 ? "0" : "") + time.getSeconds();
        var clean = sanitizeConsole(message);
        // An all-control line (a bare cursor move) carries nothing to show.
        if (clean === "" && String(message) !== "")
            return;
        logTextArea.append("[" + timestamp + "] " + clean);
        logTextArea.cursorPosition = logTextArea.length
        console.log(clean);
    }

    // Sync process (runs uv sync first)
    UI.Process {
        id: syncProcess
        program: uvPath

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
                            text: "Preset"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        ComboBox {
                            id: modelTypeCombo
                            Layout.fillWidth: true
                            model: modelPresets.map(function(p) { return p.label })
                            currentIndex: 0
                            font.pixelSize: appStyle.fontSizeBody
                            // Applied on change and once on load, so the fields and the
                            // build parameters start out matching the default preset
                            // rather than train-lora.py's own 1024 defaults.
                            //
                            // Indexes the array rather than reading an intermediate
                            // `preset: modelPresets[currentIndex]` binding: that binding
                            // has not necessarily re-evaluated by the time this handler
                            // runs, and apply() then writes the *previous* preset's values
                            // back. Measured -- picking "SDXL base 1.0" logged
                            // `idx=3 preset.label=SDXS-sketch 512`.
                            function apply() {
                                modelView.applyBuildPreset(modelPresets[currentIndex])
                            }
                            Component.onCompleted: apply()
                            onCurrentIndexChanged: apply()
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
                            placeholderText: "HuggingFace model ID or local path"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "ControlNet"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        TextField {
                            id: controlNetField
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            placeholderText: "HuggingFace ControlNet repo — empty for none"
                        }
                    }

                    // train-lora.py loads the IP-Adapter checkpoint off disk, so unlike
                    // the model and ControlNet this one cannot be a repo id.
                    RowLayout {
                        Layout.fillWidth: true
                        visible: activePreset && activePreset.ipadapterNeeded === true
                        Label {
                            text: "IP-Adapter"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                            color: ipadapterField.text === "" ? appStyle.errorColor
                                                              : appStyle.textColor
                        }
                        TextField {
                            id: ipadapterField
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            placeholderText: activePreset && activePreset.ipadapterHint
                                             ? "local path to " + activePreset.ipadapterHint
                                             : "local path to the IP-Adapter checkpoint"
                        }
                        Button {
                            text: "…"
                            font.pixelSize: appStyle.fontSizeBody
                            onClicked: ipadapterFileDialog.open()
                        }
                    }

                    FileDialog {
                        id: ipadapterFileDialog
                        title: "Select IP-Adapter Checkpoint"
                        nameFilters: ["IP-Adapter checkpoints (*.bin *.safetensors)", "All files (*)"]
                        onAccepted: {
                            if (!selectedFile)
                                return;
                            ipadapterField.text = new URL(selectedFile).pathname.substr(isWin32 ? 1 : 0);
                        }
                    }

                    // The preset carries flags with no widget of their own; show them so
                    // the command is never a surprise.
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        wrapMode: Text.WordWrap
                        font.pixelSize: appStyle.fontSizeSmall
                        font.family: "monospace"
                        color: appStyle.textColorSecondary
                        text: activePreset ? BuildPresets.extraSummary(activePreset) : ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Output Path"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                            color: outputPathField.text === "" ? "#FF3B30" : appStyle.textColor
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

                    Label {
                        visible: outputPathField.text === ""
                        text: "Select an output folder to enable build"
                        font.pixelSize: appStyle.fontSizeSmall
                        color: "#FF3B30"
                        Layout.fillWidth: true
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
                    title: "Caches"
                    description: "A first build downloads ~11 GB of wheels and several GB of model "
                               + "weights. Both are reused by every later build, so put them on a "
                               + "volume with room — and keep the wheel cache on the same volume as "
                               + "the build, or uv copies instead of hardlinking."

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Wheel cache"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        TextField {
                            id: uvCacheField
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            placeholderText: modelView.workspaceDir + "/uv-cache"
                            onTextChanged: buildSettings.uvCacheDir = text
                        }
                        Button {
                            text: "Browse"
                            font.pixelSize: appStyle.fontSizeBody
                            onClicked: uvCacheFolderDialog.open()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Model cache"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        TextField {
                            id: modelCacheField
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            placeholderText: modelView.workspaceDir + "/hf-cache"
                            onTextChanged: buildSettings.modelCacheDir = text
                        }
                        Button {
                            text: "Browse"
                            font.pixelSize: appStyle.fontSizeBody
                            onClicked: modelCacheFolderDialog.open()
                        }
                    }

                    FolderDialog {
                        id: uvCacheFolderDialog
                        title: "Select Wheel Cache Folder"
                        onAccepted: {
                            if (!selectedFolder)
                                return;
                            uvCacheField.text = new URL(selectedFolder).pathname.substr(isWin32 ? 1 : 0);
                        }
                    }

                    FolderDialog {
                        id: modelCacheFolderDialog
                        title: "Select Model Cache Folder"
                        onAccepted: {
                            if (!selectedFolder)
                                return;
                            modelCacheField.text = new URL(selectedFolder).pathname.substr(isWin32 ? 1 : 0);
                        }
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
                                    value: 512
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
                                    value: 512
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
                                    value: 512
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
                                    value: 512
                                    stepSize: 64
                                    font.pixelSize: appStyle.fontSizeBody
                                }
                            }
                        }
                    }

                    // RIFE interpolates decoded RGB, so it is model-agnostic: any bundle
                    // can carry the plan the node's "Interpolation exp" control needs.
                    // Klein always ships it; everything else has to opt in at build time.
                    CheckBox {
                        id: rifeCheckBox
                        Layout.topMargin: 4
                        text: "Build the RIFE frame-interpolation engine"
                        font.pixelSize: appStyle.fontSizeBody
                        checked: false
                        enabled: (!activePreset || activePreset.type !== "klein")
                                 && builderSupports("--rife")
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
                                enabled: runtime !== true
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
                            // ":runtime" keeps the LoRA UNFUSED and gives the engine a
                            // lora_scale input the node's knob drives live. Mutually
                            // exclusive with a baked weight, so the spinbox goes dead.
                            CheckBox {
                                text: "Runtime"
                                font.pixelSize: appStyle.fontSizeSmall
                                checked: runtime === true
                                onToggled: loraListModel.setProperty(index, "runtime", checked)
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
                                "weight": 1.0,
                                "runtime": false
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
                    color: buildStatus === "failed" ? "#f44336" : "#4CAF50"
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }

            Label {
                text: buildStatus === "running" ? Math.round(buildProgressValue) + "%"
                    : buildStatus === "success" ? "Done"
                    : "Failed"
                font.pixelSize: appStyle.fontSizeSmall
                color: buildStatus === "failed" ? "#f44336" : "#4CAF50"
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
                    text: "Build Log"
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

                TapHandler {
                    onTapped: logExpanded = !logExpanded
                }
                HoverHandler {
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

    // Lays out the writable workspace uv runs in. Copies the two project files
    // verbatim so a package update cannot leave a stale lock behind.
    function prepareWorkspace() {
        if (!Util.makeDir(workspaceDir) && !Util.isDir(workspaceDir)) {
            log("[Error] Cannot create the build workspace at: " + workspaceDir);
            return false;
        }
        Util.makeDir(uvCacheDir);
        Util.makeDir(modelCacheDir);
        var files = ["pyproject.toml", "uv.lock"];
        for (var i = 0; i < files.length; i++) {
            var src = scriptDir + "/" + files[i];
            if (!Util.fileExists(src)) {
                log("[Error] Missing from the package: " + src);
                return false;
            }
            Util.writeFile(workspaceDir + "/" + files[i], Util.readFile(src));
        }
        // uv's --cache-dir covers only the wheels; the model weights follow HF_HOME,
        // which train-lora.py reads straight out of the environment and which
        // Score.UI.Process cannot set -- so hand it to the child through uv.
        Util.writeFile(envFilePath,
                       "HF_HOME=" + modelCacheDir.replace(/\\/g, "/") + "\n");
        return true;
    }

    // builder.py reuses any existing <name>.engine in the output directory keyed on
    // FILENAME ALONE (tensorrt/builder.py:99 "Found cached engine"). Resolution,
    // batch, ControlNet and even the base model do not invalidate it. So building a
    // second preset into a folder that already holds a bundle yields the FIRST
    // bundle, in seconds, with exit code 0 and .engine files present -- which is
    // exactly what this view reports as success. Refuse instead.
    function bundleConflict() {
        var manifest = outputPathField.text + "/bundle.json";
        if (!Util.fileExists(manifest))
            return "";
        var b;
        try {
            b = JSON.parse(String(Util.readFile(manifest)));
        } catch (e) {
            return "the folder holds an unreadable bundle.json";
        }
        var diffs = [];
        if (b.base_model && b.base_model !== modelSourceField.text)
            diffs.push("model " + b.base_model + " != " + modelSourceField.text);
        var cn = controlNetField.text === "" ? null : controlNetField.text;
        if ((b.controlnet_repo || null) !== cn)
            diffs.push("controlnet " + (b.controlnet_repo || "none") + " != " + (cn || "none"));
        if (b.resolution && (b.resolution.opt_width !== optWidthSpinBox.value
                             || b.resolution.opt_height !== optHeightSpinBox.value))
            diffs.push("size " + b.resolution.opt_width + "x" + b.resolution.opt_height
                       + " != " + optWidthSpinBox.value + "x" + optHeightSpinBox.value);
        if (b.batch && b.batch.max !== maxBatchSpinBox.value)
            diffs.push("max batch " + b.batch.max + " != " + maxBatchSpinBox.value);
        return diffs.join(", ");
    }

    // Start build: first sync, then run
    function startBuild() {
        var errors = [];
        if (modelSourceField.text === "") errors.push("Model source path is empty");
        if (outputPathField.text === "") errors.push("Output path is empty");
        if (maxBatchSpinBox.value < minBatchSpinBox.value) errors.push("Max batch must be >= min batch");
        if (optBatchSpinBox.value < minBatchSpinBox.value || optBatchSpinBox.value > maxBatchSpinBox.value) errors.push("Opt batch must be between min and max batch");
        if (maxResolutionSpinBox.value < minResolutionSpinBox.value) errors.push("Max resolution must be >= min resolution");
        if (activePreset && activePreset.ipadapterNeeded === true && ipadapterField.text === "")
            errors.push("This preset needs an IP-Adapter checkpoint path");
        var unsupported = activePreset ? unsupportedFlags(activePreset) : [];
        if (rifeCheckBox.checked && !builderSupports("--rife"))
            unsupported.push("--rife");
        if (unsupported.length > 0)
            errors.push("The engine builder in this package lacks "
                        + unsupported.join(", ") + ". It is staged from koaia's "
                        + "librediffusion pin; bump that to use this preset.");
        var conflict = outputPathField.text !== "" ? bundleConflict() : "";
        if (conflict !== "")
            errors.push("The output folder already holds a different bundle (" + conflict
                        + "). Engines are reused by filename, so this would silently keep the "
                        + "old ones. Pick an empty folder or delete that one.");
        if (errors.length > 0) {
            for (var i = 0; i < errors.length; i++)
                log("[Error] " + errors[i]);
            return;
        }

        if (!prepareWorkspace())
            return;

        buildStatus = "running"
        buildProgressValue = 0
        logExpanded = true
        progressAnimation.restart()

        syncProcess.clearOutput();
        buildProcess.clearOutput();

        syncProcess.arguments = ["--cache-dir", uvCacheDir, "sync"];
        syncProcess.workingDirectory = workspaceDir;
        buildProcess.workingDirectory = workspaceDir;

        log("[Syncing environment in " + workspaceDir + "]");
        log("$ " + uvPath + " " + syncProcess.arguments.join(" "));
        log("[Wheel cache " + uvCacheDir + "]");
        log("[Model cache " + modelCacheDir + "]");
        log("----------------------------------------");

        syncProcess.start();
    }

    // Called after successful sync
    function runBuildProcess() {
        var p = activePreset;
        // --env-file is the only way to hand HF_HOME to train-lora.py: Score.UI.Process
        // exposes program/arguments/workingDirectory and no environment.
        var args = ["--cache-dir", uvCacheDir,
                    "run", "--env-file", envFilePath, "python", scriptPath,
                    "--type", p.type,
                    "--model", modelSourceField.text,
                    "--output", outputPathField.text,
                    "--min-batch", minBatchSpinBox.value.toString(),
                    "--max-batch", maxBatchSpinBox.value.toString(),
                    "--opt-batch", optBatchSpinBox.value.toString(),
                    "--min-resolution", minResolutionSpinBox.value.toString(),
                    "--max-resolution", maxResolutionSpinBox.value.toString(),
                    "--opt-width", optWidthSpinBox.value.toString(),
                    "--opt-height", optHeightSpinBox.value.toString()];

        // Exports controlnet.engine plus a control-aware unet.engine; without it the
        // bundle has no ControlNet and every SD_*_CONTROLNET workflow refuses frames.
        if (controlNetField.text !== "")
            args.push("--controlnet", controlNetField.text);

        if (ipadapterField.text !== "")
            args.push("--ipadapter", ipadapterField.text);

        if (rifeCheckBox.checked && rifeCheckBox.enabled)
            args.push("--rife");

        args = args.concat(BuildPresets.extraArgs(p));

        // Add LoRAs with weights
        for (var i = 0; i < loraListModel.count; i++) {
            var lora = loraListModel.get(i);
            if (lora.path !== "") {
                var loraArg = lora.path;
                if (lora.runtime) {
                    loraArg += ":runtime";
                } else if (lora.weight !== 1.0) {
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
        log("$ cd " + workspaceDir + " && " + cmdLine);
        log("----------------------------------------");

        buildProcess.workingDirectory = workspaceDir;
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
