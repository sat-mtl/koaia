import QtCore
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import Score.UI as UI
import koaia
import "../Scripts/ConfigManager.js" as ConfigManager

Pane {
    id: mainView

    readonly property bool isWin32: Qt.platform.os === "windows"
    readonly property url defaultConfigUrl: Qt.resolvedUrl("../../default.koaia")

    // Video file existence check — scans parent dir for the exact filename
    readonly property string _videoParentUrl: {
        var p = imagePathField.text.replace(/\\/g, '/')
        var dir = p.substring(0, p.lastIndexOf('/'))
        return dir ? ((isWin32 ? "file:///" : "file://") + dir) : ""
    }
    readonly property string _videoFileName: {
        var p = imagePathField.text.replace(/\\/g, '/')
        return p.substring(p.lastIndexOf('/') + 1)
    }
    readonly property bool videoFileExists: _videoFileName !== "" && videoFileModel.count > 0

    // Engine folder validation
    readonly property string _engineFolderUrl: {
        if (!enginePathField.text) return ""
        return (isWin32 ? "file:///" : "file://") + enginePathField.text.replace(/\\/g, '/')
    }
    readonly property bool engineHasFiles:  engineFilesModel.count > 0
    readonly property bool engineHasOnnx:   engineOnnxModel.count > 0

    FolderListModel {
        id: videoFileModel
        showFiles: true
        showDirs: false
        folder: mainView._videoParentUrl
        nameFilters: mainView._videoFileName ? [mainView._videoFileName] : []
    }

    FolderListModel {
        id: engineFilesModel
        showFiles: true
        showDirs: false
        nameFilters: ["*.engine"]
        folder: mainView._engineFolderUrl
    }

    FolderListModel {
        id: engineOnnxModel
        showFiles: true
        showDirs: false
        nameFilters: ["*.onnx"]
        folder: mainView._engineFolderUrl ? mainView._engineFolderUrl + "/onnx" : ""
    }

    property bool isProcessing: false
    onIsProcessingChanged: {
        if (isProcessing) {
            Score.play()
            Qt.callLater(pushValuesToScore)
        } else {
            Score.stop()
        }
    }

    // Re-pushes all current UI values to Score after play() resets port state.
    function pushValuesToScore() {
        var p = processes
        try {
            if (p.prompt_composer.keywords)
                Score.setValue(p.prompt_composer.keywords, promptTextField.text)
            if (p.streamDiffusion.workflow)
                Score.setValue(p.streamDiffusion.workflow, workflowCombo.currentIndex)
            if (p.streamDiffusion.engines)
                Score.setValue(p.streamDiffusion.engines, enginePathField.text)
            if (p.streamDiffusion.seed)
                Score.setValue(p.streamDiffusion.seed, seedSpinBox.value)
            if (p.streamDiffusion.timesteps)
                Score.setValue(p.streamDiffusion.timesteps, timestepsField.text)
            if (p.streamDiffusion.guidance)
                Score.setValue(p.streamDiffusion.guidance, guidanceSlider.value)
            if (p.streamDiffusion.guidance_type)
                Score.setValue(p.streamDiffusion.guidance_type, guidanceTypeCombo.currentIndex)
            if (p.streamDiffusion.delta)
                Score.setValue(p.streamDiffusion.delta, deltaSlider.value)
            if (p.streamDiffusion.denoising_batch)
                Score.setValue(p.streamDiffusion.denoising_batch, denoisingBatchSpinBox.checked)
            if (p.streamDiffusion.add_noise)
                Score.setValue(p.streamDiffusion.add_noise, addNoiseCheckBox.checked)
            if (p.streamDiffusion.manual_mode)
                Score.setValue(p.streamDiffusion.manual_mode, manualModeCheckBox.checked)
            if (p.streamDiffusion.resolution)
                Score.setValue(p.streamDiffusion.resolution, sizeCombo.currentDimensions)
            if (p.shape.maskShapeMode)
                Score.setValue(p.shape.maskShapeMode, shapeTypeCombo.currentIndex)
            if (p.shape.color) {
                var c = Qt.hsla(hueSlider.value, 0.7, brightnessSlider.value, 1.0)
                Score.setValue(p.shape.color, [c.r, c.g, c.b, 1.0])
            }
            if (p.shape.shapeWidth)
                Score.setValue(p.shape.shapeWidth, shapeWidthSlider.value)
            if (p.shape.shapeHeight)
                Score.setValue(p.shape.shapeHeight, shapeHeightSlider.value)
            if (p.shape.horizontalRepeat)
                Score.setValue(p.shape.horizontalRepeat, shapeHRepeatSlider.value)
            if (p.shape.verticalRepeat)
                Score.setValue(p.shape.verticalRepeat, shapeVRepeatSlider.value)
            if (p.shape.center)
                Score.setValue(p.shape.center, [shapex.value / 512.0, shapey.value / 512.0])
            if (p.shape.invertMask)
                Score.setValue(p.shape.invertMask, invertCheckBox.checked)
            if (p.video_Mixer.alpha1)
                Score.setValue(p.video_Mixer.alpha1, shapeAmountSlider.slider.value)
            if (p.video_Mixer.alpha2)
                Score.setValue(p.video_Mixer.alpha2, smokeAmountSlider.slider.value)
            if (p.video_Mixer.alpha3)
                Score.setValue(p.video_Mixer.alpha3, voronoiAmountSlider.slider.value)
            if (p.video_Mixer.alpha4)
                Score.setValue(p.video_Mixer.alpha4, noiseAmountSlider.slider.value)
            if (p.video_Mixer.alpha5)
                Score.setValue(p.video_Mixer.alpha5, perlinAmountSlider.slider.value)
            if (p.video_Mixer.alpha7)
                Score.setValue(p.video_Mixer.alpha7, imageAmountSlider.slider.value)
            if (p.video_Mixer.alpha8)
                Score.setValue(p.video_Mixer.alpha8, cameraAmountSlider.slider.value)
            if (p.voronoi.seed)        Score.setValue(p.voronoi.seed,        shaderControls.voronoiSeed)
            if (p.voronoi.iregularity) Score.setValue(p.voronoi.iregularity, shaderControls.voronoiIregularity)
            if (p.voronoi.blur)        Score.setValue(p.voronoi.blur,        shaderControls.voronoiBlur)
            if (p.voronoi.scale)       Score.setValue(p.voronoi.scale,       shaderControls.voronoiScale)
            if (p.white_Noise.seed)    Score.setValue(p.white_Noise.seed,    shaderControls.whiteNoiseSeed)
            if (p.perlin_Noise.seed)   Score.setValue(p.perlin_Noise.seed,   shaderControls.perlinSeed)
            if (p.perlin_Noise.scale)  Score.setValue(p.perlin_Noise.scale,  shaderControls.perlinScale)
        } catch(e) {
            console.warn("[MainView] pushValuesToScore error:", e)
        }
    }

    Settings {
        id: appSettings
        category: "Koaia"

        // Input section
        property string videoPath: ""
        property real videoAmount: 0.0
        property real cameraAmount: 0.0

        // AI Model section
        property string prompt: "origami, hyperrealistic, 4k, abstract, geometry"
        property int workflow: 0
        property string enginePath: ""
        property int seed: 20
        property string timesteps: "20"
        property real guidance: 1.0
        property int guidanceType: 0
        property real delta: 1.0
        property bool denoisingBatch: false
        property bool addNoise: false
        property bool manualMode: false
        property int resolution: 0

        // Noise layer section
        property int noiseShader: 0
        property real smokeAmount: 0.0
        property real voronoiAmount: 0.0
        property real noiseAmount: 0.0
        property real perlinAmount: 0.0
        property real voronoiSeed: 0.3
        property real voronoiIregularity: 0.3
        property real voronoiBlur: 0.3
        property real voronoiScale: 0.4
        property real whiteNoiseSeed: 0.3
        property real perlinSeed: 0.3
        property real perlinScale: 0.3

        // Shape layer section
        property int shapeType: 1
        property real shapeAmount: 0.0
        property real shapeBrightness: 0.1
        property real shapeHue: 0.0
        property real shapeWidth: 0.5
        property real shapeHeight: 0.5
        property real shapeHRepeat: 1
        property real shapeVRepeat: 1
        property int shapeX: 256
        property int shapeY: 256
        property bool shapeInvert: false
    }

    Component.onCompleted: {
        loadConfigFromUrl(defaultConfigUrl, true)
    }

    // Returns the absolute filesystem path for a file inside media/.
    // Use this instead of hardcoding paths — works in dev and in packaged builds.
    function mediaPath(filename) {
        var url = Qt.resolvedUrl("../../media/" + filename)
        var path = new URL(url.toString()).pathname
        return isWin32 ? path.substr(1) : path
    }

    function doSave(fileUrl) {
        mainView.forceActiveFocus()
        var jsonConfig = ConfigManager.exportConfig(appSettings)
        // Re-tokenise the bundled media path so saved files stay portable across machines.
        var mediaDirPath = mediaPath("").replace(/\/+$/, "")
        if (mediaDirPath) jsonConfig = jsonConfig.split(mediaDirPath).join("{{media}}")
        ConfigManager.saveConfigToFile(jsonConfig, fileUrl, function(success, error) {
            configStatusLabel.isError = !success
            configStatusLabel.text = success
                ? "Saved: " + fileUrl.toString().split("/").pop()
                : "Save failed: " + (error || "unknown error")
            if (success) {
                console.log("[MainView] Config saved to:", fileUrl)
            } else {
                console.error("[MainView] Failed to save config:", error)
            }
        })
    }

    // Writes config values into appSettings then pushes them to the UI and Score.
    function applyConfig(config) {
        var i = config.input
        if (i) {
            var rawPath = i.videoPath || ""
            // Resolve {{media}} token to the bundled media/ directory path.
            // Fall back to glow.mp4 when no video is specified — Score crashes without one.
            if (rawPath.indexOf("{{media}}") !== -1) {
                rawPath = rawPath.replace("{{media}}", mediaPath("").replace(/\/$/, ""))
            } else if (!rawPath) {
                rawPath = mediaPath("glow.mp4")
            }
            appSettings.videoPath    = rawPath
            appSettings.videoAmount  = i.videoAmount  || 0
            appSettings.cameraAmount = i.cameraAmount || 0
        }
        var ai = config.aiModel
        if (ai) {
            appSettings.prompt         = ai.prompt        || ""
            appSettings.workflow       = ai.workflow       || 0
            appSettings.enginePath     = ai.enginePath     || ""
            appSettings.seed           = ai.seed           !== undefined ? ai.seed      : 20
            appSettings.timesteps      = ai.timesteps      || "20"
            appSettings.guidance       = ai.guidance       !== undefined ? ai.guidance  : 1.0
            appSettings.guidanceType   = ai.guidanceType   || 0
            appSettings.delta          = ai.delta          !== undefined ? ai.delta     : 1.0
            appSettings.denoisingBatch = ai.denoisingBatch || false
            appSettings.addNoise       = ai.addNoise       || false
            appSettings.manualMode     = ai.manualMode     || false
            appSettings.resolution     = ai.resolution     || 0
        }
        var n = config.noiseLayer
        if (n) {
            appSettings.noiseShader        = n.noiseShader        || 0
            appSettings.smokeAmount        = n.smokeAmount        || 0
            appSettings.voronoiAmount      = n.voronoiAmount      || 0
            appSettings.noiseAmount        = n.noiseAmount        || 0
            appSettings.perlinAmount       = n.perlinAmount       || 0
            appSettings.voronoiSeed        = n.voronoiSeed        !== undefined ? n.voronoiSeed        : 0.3
            appSettings.voronoiIregularity = n.voronoiIregularity !== undefined ? n.voronoiIregularity : 0.3
            appSettings.voronoiBlur        = n.voronoiBlur        !== undefined ? n.voronoiBlur        : 0.3
            appSettings.voronoiScale       = n.voronoiScale       !== undefined ? n.voronoiScale       : 0.4
            appSettings.whiteNoiseSeed     = n.whiteNoiseSeed     !== undefined ? n.whiteNoiseSeed     : 0.3
            appSettings.perlinSeed         = n.perlinSeed         !== undefined ? n.perlinSeed         : 0.3
            appSettings.perlinScale        = n.perlinScale        !== undefined ? n.perlinScale        : 0.3
        }
        var sh = config.shapeLayer
        if (sh) {
            appSettings.shapeType       = sh.shapeType    || 0
            appSettings.shapeAmount     = sh.shapeAmount  || 0
            appSettings.shapeBrightness = sh.brightness   || 0.1
            appSettings.shapeHue        = sh.hue          || 0
            appSettings.shapeWidth      = sh.shapeWidth   !== undefined ? sh.shapeWidth   : 0.5
            appSettings.shapeHeight     = sh.shapeHeight  !== undefined ? sh.shapeHeight  : 0.5
            appSettings.shapeHRepeat    = sh.shapeHRepeat !== undefined ? sh.shapeHRepeat : 1
            appSettings.shapeVRepeat    = sh.shapeVRepeat !== undefined ? sh.shapeVRepeat : 1
            appSettings.shapeX          = sh.shapeX       !== undefined ? sh.shapeX       : 256
            appSettings.shapeY          = sh.shapeY       !== undefined ? sh.shapeY       : 256
            appSettings.shapeInvert     = sh.invert        || false
        }
        restoreSavedSettings()
    }

    // Loads a .koaia file by URL and applies it. Pass silent=true on startup to
    // suppress status label updates (avoids "Loaded: default.koaia" flash).
    function loadConfigFromUrl(fileUrl, silent) {
        var fileUrlStr = fileUrl.toString()
        ConfigManager.loadConfigFromFile(fileUrlStr, function(success, jsonText, error) {
            if (!success) {
                if (!silent) {
                    configStatusLabel.isError = true
                    configStatusLabel.text = "Load failed: " + (error || "unknown error")
                }
                console.error("[MainView] Failed to load config:", fileUrlStr, error)
                return
            }
            var config
            try { config = JSON.parse(jsonText) }
            catch (e) {
                console.error("[MainView] Invalid config JSON:", e.message)
                if (!silent) {
                    configStatusLabel.isError = true
                    configStatusLabel.text = "Invalid config file"
                }
                return
            }
            var validation = ConfigManager.validateConfig(config)
            if (!validation.valid) {
                console.error("[MainView] Config validation failed:", validation.errors.join(", "))
                if (!silent) {
                    configStatusLabel.isError = true
                    configStatusLabel.text = "Invalid config: " + validation.errors[0]
                }
                return
            }
            applyConfig(config)
            if (!silent) {
                configStatusLabel.isError = false
                configStatusLabel.text = "Loaded: " + fileUrlStr.split("/").pop()
            }
            console.log("[MainView] Config loaded from:", fileUrlStr)
        })
    }

    // Called after every config load — pushes appSettings values into UI controls,
    // which in turn fire onValueChanged and push to Score.
    function restoreSavedSettings() {
        // Input section
        imagePathField.text = appSettings.videoPath;
        imageAmountSlider.value = appSettings.videoAmount;
        cameraAmountSlider.value = appSettings.cameraAmount;

        // AI Model section
        promptTextField.text = appSettings.prompt;
        workflowCombo.currentIndex = appSettings.workflow;
        enginePathField.text = appSettings.enginePath;
        seedSpinBox.value = appSettings.seed;
        timestepsField.text = appSettings.timesteps;
        guidanceSlider.value = appSettings.guidance;
        guidanceTypeCombo.currentIndex = appSettings.guidanceType;
        deltaSlider.value = appSettings.delta;
        denoisingBatchSpinBox.checked = appSettings.denoisingBatch;
        addNoiseCheckBox.checked = appSettings.addNoise;
        manualModeCheckBox.checked = appSettings.manualMode;
        sizeCombo.currentIndex = appSettings.resolution;

        // Noise layer section
        inputNoiseChooser.currentIndex = appSettings.noiseShader;
        smokeAmountSlider.value = appSettings.smokeAmount;
        voronoiAmountSlider.value = appSettings.voronoiAmount;
        noiseAmountSlider.value = appSettings.noiseAmount;
        perlinAmountSlider.value = appSettings.perlinAmount;
        shaderControls.voronoiSeed        = appSettings.voronoiSeed;
        shaderControls.voronoiIregularity = appSettings.voronoiIregularity;
        shaderControls.voronoiBlur        = appSettings.voronoiBlur;
        shaderControls.voronoiScale       = appSettings.voronoiScale;
        shaderControls.whiteNoiseSeed     = appSettings.whiteNoiseSeed;
        shaderControls.perlinSeed         = appSettings.perlinSeed;
        shaderControls.perlinScale        = appSettings.perlinScale;

        // Shape layer section
        shapeTypeCombo.currentIndex = appSettings.shapeType;
        shapeAmountSlider.value = appSettings.shapeAmount;
        brightnessSlider.value = appSettings.shapeBrightness;
        hueSlider.value = appSettings.shapeHue;
        shapeWidthSlider.value = appSettings.shapeWidth;
        shapeHeightSlider.value = appSettings.shapeHeight;
        shapeHRepeatSlider.value = appSettings.shapeHRepeat;
        shapeVRepeatSlider.value = appSettings.shapeVRepeat;
        shapex.value = appSettings.shapeX;
        shapey.value = appSettings.shapeY;
        invertCheckBox.checked = appSettings.shapeInvert;
    }

    // Score process objects
    ProcessObjects {
        id: processes
    }

    component Section: ColumnLayout {
        property string title: ""
        property string description: ""
        default property alias content: body.data
        spacing: 0

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            Layout.topMargin: appStyle.spacing
            Layout.bottomMargin: 6
            spacing: 8

            CustomLabel {
                id: headerLabel
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

    ScrollView {
        id: leftScroll
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: configToolbar.top
        anchors.topMargin: appStyle.padding
        anchors.leftMargin: appStyle.padding
        anchors.rightMargin: appStyle.padding
        spacing: appStyle.spacing

        clip: true
        contentWidth: availableWidth // viewport width?

        ColumnLayout {
            id: leftContent
            width: leftScroll.availableWidth
            spacing: appStyle.spacing

            Section {
                title: "Input"
                description: "Configure input sources for image, video, and camera feeds"

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Video input"
                        Layout.preferredWidth: 100
                        font.pixelSize: appStyle.fontSizeBody
                    }
                    TextField {
                        id: imagePathField
                        Layout.fillWidth: true
                        font.pixelSize: appStyle.fontSizeBody
                        placeholderText: "/path/to/video.mp4"

                        property var videoProcess: processes.genai_inputvideo.process_object

                        onTextChanged: {
                            appSettings.videoPath = text;
                            if (videoProcess && text !== "") {
                                var wasPlaying = isProcessing;
                                if (wasPlaying) isProcessing = false;  // handler calls Score.stop()
                                videoProcess.path = text;
                                if (wasPlaying) Qt.callLater(function() { isProcessing = true; });  // handler calls Score.play()
                            }
                        }
                    }
                    Button {
                        text: "Browse"
                        font.pixelSize: appStyle.fontSizeBody
                        onClicked: imageFileDialog.open()
                    }
                }

                FileDialog {
                    id: imageFileDialog
                    title: "Select Video File"
                    nameFilters: ["Video Files (*.mp4 *.avi *.mov *.mkv *.webm *.flv)"]
                    onAccepted: {
                        if (!selectedFile) {
                            console.log("No file selected");
                            return;
                        }
                        var filePath = new URL(selectedFile).pathname.substr(isWin32 ? 1 : 0);
                        imagePathField.text = filePath;
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: appStyle.spacing
                    AmountSlider {
                        id: imageAmountSlider
                        Layout.fillWidth: true
                        label: "Video"
                        value: 0.0
                        port: processes.video_Mixer.alpha7
                        enabled: imagePathField.text !== ""

                        Connections {
                            target: imageAmountSlider.slider
                            function onValueChanged() {
                                appSettings.videoAmount = imageAmountSlider.slider.value;
                            }
                        }
                    }
                    AmountSlider {
                        id: cameraAmountSlider
                        Layout.fillWidth: true
                        label: "Camera"
                        value: 0.0
                        port: processes.video_Mixer.alpha8
                        Connections {
                            target: cameraAmountSlider.slider
                            function onValueChanged() {
                                appSettings.cameraAmount = cameraAmountSlider.slider.value;
                            }
                        }
                    }
                }

                Label {
                    visible: imagePathField.text === ""
                    text: "Select a video file to enable"
                    font.pixelSize: appStyle.fontSizeSmall
                    color: appStyle.textColorSecondary
                    Layout.fillWidth: true
                }
                Label {
                    visible: imagePathField.text !== "" && !mainView.videoFileExists
                    text: "File not found"
                    font.pixelSize: appStyle.fontSizeSmall
                    color: "#FF3B30"
                    Layout.fillWidth: true
                }
            }

            Section {
                id: aiModelSection
                title: "AI model"
                description: "Configure AI image generation parameters including prompts, seed, and steps"

                property bool showAdvancedOptions: appSettings.enginePath === ""

                Label {
                    text: "Prompt"
                    font.pixelSize: appStyle.fontSizeBody
                }

                TextArea {
                    id: promptTextField
                    text: "origami, hyperrealistic, 4k, abstract, geometry"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    font.pixelSize: appStyle.fontSizeBody
                    color: appStyle.textColor
                    wrapMode: TextArea.Wrap
                    background: Rectangle {
                        color: appStyle.backgroundColorSecondary
                        border.color: appStyle.borderColor
                        border.width: 1
                        radius: appStyle.borderRadius
                    }
                    UI.PortSource on text {
                        port: processes.prompt_composer.keywords
                    }
                    Component.onCompleted: if (processes.prompt_composer.keywords)
                        Score.setValue(processes.prompt_composer.keywords, text)
                    onTextChanged: {
                        if (processes.prompt_composer.keywords)
                            Score.setValue(processes.prompt_composer.keywords, text);
                        appSettings.prompt = text;
                    }
                }

                // Advanced options toggle
                Button {
                    Layout.fillWidth: true
                    Layout.topMargin: appStyle.spacing
                    text: aiModelSection.showAdvancedOptions ? "Hide Advanced Options" : "Show Advanced Options"
                    font.pixelSize: appStyle.fontSizeBody
                    onClicked: aiModelSection.showAdvancedOptions = !aiModelSection.showAdvancedOptions
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: aiModelSection.showAdvancedOptions
                    spacing: appStyle.spacing

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Workflow"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        ComboBox {
                            id: workflowCombo
                            Layout.fillWidth: true
                            model: ["SD_TXT2IMG", "SD_IMG2IMG", "SD_TXT2IMG_CONTROLNET", "SD_TXT2IMG_IPADAPTER", "SD_IMG2IMG_IPADAPTER", "STURBO_TXT2IMG", "SDTURBO_IMG2IMG", "SDXL_TXT2IMG", "SDXL_IMG2IMG", "V2V_TXT2IMG", "V2V_IMG2IMG"]
                            currentIndex: 0
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on currentIndex {
                                port: processes.streamDiffusion.workflow
                            }
                            Component.onCompleted: if (processes.streamDiffusion.workflow)
                                Score.setValue(processes.streamDiffusion.workflow, currentIndex)
                            onCurrentIndexChanged: {
                                if (processes.streamDiffusion.workflow)
                                    Score.setValue(processes.streamDiffusion.workflow, currentIndex);
                                appSettings.workflow = currentIndex;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Engine"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                            color: enginePathField.text === "" ? "#FF3B30" : appStyle.textColor
                        }
                        TextField {
                            id: enginePathField
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            text: ""
                            placeholderText: "Path to engine folder"
                            UI.PortSource on text {
                                port: processes.streamDiffusion.engines
                            }
                            Component.onCompleted: if (processes.streamDiffusion.engines)
                                Score.setValue(processes.streamDiffusion.engines, text)
                            onTextChanged: {
                                if (processes.streamDiffusion.engines)
                                    Score.setValue(processes.streamDiffusion.engines, text);
                                appSettings.enginePath = text;
                            }
                        }
                        Button {
                            text: "Browse"
                            font.pixelSize: appStyle.fontSizeBody
                            onClicked: engineFolderDialog.open()
                        }
                    }

                    Label {
                        visible: enginePathField.text === ""
                        text: "Select an engine folder to enable start"
                        font.pixelSize: appStyle.fontSizeSmall
                        color: "#FF3B30"
                        Layout.fillWidth: true
                    }
                    Label {
                        visible: enginePathField.text !== "" && !mainView.engineHasFiles
                        text: "No .engine files found in this folder"
                        font.pixelSize: appStyle.fontSizeSmall
                        color: "#FF3B30"
                        Layout.fillWidth: true
                    }
                    Label {
                        visible: enginePathField.text !== "" && mainView.engineHasFiles && !mainView.engineHasOnnx
                        text: "Missing onnx subfolder"
                        font.pixelSize: appStyle.fontSizeSmall
                        color: "#FF9500"
                        Layout.fillWidth: true
                    }
                    Label {
                        visible: enginePathField.text !== "" && mainView.engineHasFiles
                        text: engineFilesModel.count + " engine" + (engineFilesModel.count === 1 ? "" : "s") + " found" + (mainView.engineHasOnnx ? "" : " — onnx missing")
                        font.pixelSize: appStyle.fontSizeSmall
                        color: mainView.engineHasOnnx ? "#34C759" : "#FF9500"
                        Layout.fillWidth: true
                    }

                    FolderDialog {
                        id: engineFolderDialog
                        title: "Select Engine Folder"
                        onAccepted: {
                            if (!selectedFolder) {
                                console.log("No folder selected");
                                return;
                            }
                            var folderPath = new URL(selectedFolder).pathname.substr(isWin32 ? 1 : 0);
                            enginePathField.text = folderPath;
                        }
                    }
                    /* JM: this has to be dynamic, with e.g. a Repeater
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Weights"; font.pixelSize: appStyle.fontSizeBody }
                            ParameterSlider {
                                Layout.fillWidth: true
                                labelText: ""
                                port: processes.prompt_composer.weights
                                from: 0
                                to: 2
                                initialValue: 1.0
                            }
                        }
*/
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Seed"
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        SpinBox {
                            id: seedSpinBox
                            editable: true
                            Layout.fillWidth: true
                            from: 0
                            to: 9999999
                            value: 20
                            stepSize: 1
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on value {
                                port: processes.streamDiffusion.seed
                            }
                            Component.onCompleted: if (processes.streamDiffusion.seed)
                                Score.setValue(processes.streamDiffusion.seed, value)
                            onValueChanged: {
                                if (processes.streamDiffusion.seed)
                                    Score.setValue(processes.streamDiffusion.seed, value);
                                appSettings.seed = value;
                            }
                        }
                        Label {
                            text: "Timesteps"
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        TextField {
                            id: timestepsField
                            Layout.fillWidth: true
                            text: "20"
                            placeholderText: "e.g. 20 or 30,45"
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on text {
                                port: processes.streamDiffusion.timesteps
                            }
                            Component.onCompleted: if (processes.streamDiffusion.timesteps)
                                Score.setValue(processes.streamDiffusion.timesteps, text)
                            onTextChanged: {
                                if (processes.streamDiffusion.timesteps)
                                    Score.setValue(processes.streamDiffusion.timesteps, text);
                                appSettings.timesteps = text;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Guidance"
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        ParameterSlider {
                            id: guidanceSlider
                            Layout.fillWidth: true
                            labelText: ""
                            port: processes.streamDiffusion.guidance
                            from: 0
                            to: 20
                            initialValue: 1.0
                            onValueChanged: appSettings.guidance = value
                        }
                        Label {
                            text: "Guidance type"
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        ComboBox {
                            id: guidanceTypeCombo
                            Layout.fillWidth: true
                            model: ["None", "Self", "Full", "Initialize"]
                            currentIndex: 0
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on currentIndex {
                                port: processes.streamDiffusion.guidance_type
                            }
                            Component.onCompleted: if (processes.streamDiffusion.guidance_type)
                                Score.setValue(processes.streamDiffusion.guidance_type, currentIndex)
                            onCurrentIndexChanged: {
                                if (processes.streamDiffusion.guidance_type)
                                    Score.setValue(processes.streamDiffusion.guidance_type, currentIndex);
                                appSettings.guidanceType = currentIndex;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Delta"
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        ParameterSlider {
                            id: deltaSlider
                            Layout.fillWidth: true
                            labelText: ""
                            port: processes.streamDiffusion.delta
                            from: 0
                            to: 2
                            initialValue: 1.0
                            stepSize: 0.01
                            onValueChanged: appSettings.delta = value
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        CheckBox {
                            id: denoisingBatchSpinBox
                            text: "Denoise Batch"
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on checked {
                                port: processes.streamDiffusion.denoising_batch
                            }
                            Component.onCompleted: if (processes.streamDiffusion.denoising_batch)
                                Score.setValue(processes.streamDiffusion.denoising_batch, checked)
                            onCheckedChanged: {
                                if (processes.streamDiffusion.denoising_batch)
                                    Score.setValue(processes.streamDiffusion.denoising_batch, checked);
                                appSettings.denoisingBatch = checked;
                            }
                        }
                        CheckBox {
                            id: addNoiseCheckBox
                            text: "Add Noise"
                            checked: false
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on checked {
                                port: processes.streamDiffusion.add_noise
                            }
                            Component.onCompleted: if (processes.streamDiffusion.add_noise)
                                Score.setValue(processes.streamDiffusion.add_noise, checked)
                            onCheckedChanged: {
                                if (processes.streamDiffusion.add_noise)
                                    Score.setValue(processes.streamDiffusion.add_noise, checked);
                                appSettings.addNoise = checked;
                            }
                        }
                        CheckBox {
                            id: manualModeCheckBox
                            text: "Manual Mode"
                            checked: false
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on checked {
                                port: processes.streamDiffusion.manual_mode
                            }
                            Component.onCompleted: if (processes.streamDiffusion.manual_mode)
                                Score.setValue(processes.streamDiffusion.manual_mode, checked)
                            onCheckedChanged: {
                                if (processes.streamDiffusion.manual_mode)
                                    Score.setValue(processes.streamDiffusion.manual_mode, checked);
                                appSettings.manualMode = checked;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Resolution"
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        ComboBox {
                            id: sizeCombo
                            Layout.fillWidth: true
                            model: ["512 x 512", "1024 x 1024"]
                            property int baseSize: 512
                            property int currentDimension: baseSize
                            property var currentDimensions: [currentDimension, currentDimension]
                            onCurrentIndexChanged: {
                                currentDimension = baseSize * (currentIndex + 1);
                                appSettings.resolution = currentIndex;
                            }
                            UI.PortSource on currentDimensions {
                                port: processes.streamDiffusion.resolution
                            }
                            Component.onCompleted: if (processes.streamDiffusion.resolution)
                                Score.setValue(processes.streamDiffusion.resolution, currentDimensions)
                            onCurrentDimensionsChanged: if (processes.streamDiffusion.resolution)
                                Score.setValue(processes.streamDiffusion.resolution, currentDimensions)
                        }
                    }
                }
            }

            Section {
                title: "Noise layer"
                description: "Control shader effects, noise patterns."

                // Shader
                RowLayout {
                    Layout.fillWidth: true
                    spacing: appStyle.spacing
                    Label {
                        text: "Shader"
                        Layout.preferredWidth: 100
                        font.pixelSize: appStyle.fontSizeBody
                    }
                    ComboBox {
                        id: inputNoiseChooser
                        Layout.preferredWidth: 150
                        model: ["Smoke", "Voronoi", "Noise", "Perlin"]
                        currentIndex: 0
                        font.pixelSize: appStyle.fontSizeBody
                        onCurrentIndexChanged: appSettings.noiseShader = currentIndex
                    }
                    // Amount sliders (check in StatusOverlay)
                    AmountSlider {
                        id: smokeAmountSlider
                        Layout.fillWidth: true
                        label: "Amount"
                        value: 0.0
                        port: processes.video_Mixer.alpha2
                        visible: inputNoiseChooser.currentIndex === 0
                        Connections {
                            target: smokeAmountSlider.slider
                            function onValueChanged() {
                                appSettings.smokeAmount = smokeAmountSlider.slider.value;
                            }
                        }
                    }
                    AmountSlider {
                        id: voronoiAmountSlider
                        Layout.fillWidth: true
                        label: "Amount"
                        value: 0.0
                        port: processes.video_Mixer.alpha3
                        visible: inputNoiseChooser.currentIndex === 1
                        Connections {
                            target: voronoiAmountSlider.slider
                            function onValueChanged() {
                                appSettings.voronoiAmount = voronoiAmountSlider.slider.value;
                            }
                        }
                    }
                    AmountSlider {
                        id: noiseAmountSlider
                        Layout.fillWidth: true
                        label: "Amount"
                        value: 0.0
                        port: processes.video_Mixer.alpha4
                        visible: inputNoiseChooser.currentIndex === 2
                        Connections {
                            target: noiseAmountSlider.slider
                            function onValueChanged() {
                                appSettings.noiseAmount = noiseAmountSlider.slider.value;
                            }
                        }
                    }
                    AmountSlider {
                        id: perlinAmountSlider
                        Layout.fillWidth: true
                        label: "Amount"
                        value: 0.0
                        port: processes.video_Mixer.alpha5
                        visible: inputNoiseChooser.currentIndex === 3
                        Connections {
                            target: perlinAmountSlider.slider
                            function onValueChanged() {
                                appSettings.perlinAmount = perlinAmountSlider.slider.value;
                            }
                        }
                    }
                }

                ShaderControls {
                    id: shaderControls
                    Layout.fillWidth: true
                    shaderType: inputNoiseChooser.currentIndex
                    voronoi: processes.voronoi
                    perlin_Noise: processes.perlin_Noise
                    white_Noise: processes.white_Noise
                    simplex_Noise: processes.simplex_Noise

                    onVoronoiSeedChanged:        appSettings.voronoiSeed        = voronoiSeed
                    onVoronoiIregularityChanged: appSettings.voronoiIregularity = voronoiIregularity
                    onVoronoiBlurChanged:        appSettings.voronoiBlur        = voronoiBlur
                    onVoronoiScaleChanged:       appSettings.voronoiScale       = voronoiScale
                    onWhiteNoiseSeedChanged:     appSettings.whiteNoiseSeed     = whiteNoiseSeed
                    onPerlinSeedChanged:         appSettings.perlinSeed         = perlinSeed
                    onPerlinScaleChanged:        appSettings.perlinScale        = perlinScale
                }
            }
            Section {
                title: "Shape layer"
                description: "Add a shape mask for compositing layers"

                // Shape
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Shape"
                        Layout.preferredWidth: 100
                        font.pixelSize: appStyle.fontSizeBody
                    }
                    ComboBox {
                        id: shapeTypeCombo
                        Layout.preferredWidth: 150
                        model: ["Rectangle", "Triangle", "Circle", "Diamond"]
                        currentIndex: 1
                        font.pixelSize: appStyle.fontSizeBody
                        UI.PortSource on currentIndex {
                            port: processes.shape.maskShapeMode
                        }
                        Component.onCompleted: if (processes.shape.maskShapeMode)
                            Score.setValue(processes.shape.maskShapeMode, currentIndex)
                        onCurrentIndexChanged: {
                            if (processes.shape.maskShapeMode)
                                Score.setValue(processes.shape.maskShapeMode, currentIndex);
                            appSettings.shapeType = currentIndex;
                        }
                    }
                    AmountSlider {
                        id: shapeAmountSlider
                        Layout.fillWidth: true
                        label: "Amount"
                        value: 0.0
                        port: processes.video_Mixer.alpha1
                        Connections {
                            target: shapeAmountSlider.slider
                            function onValueChanged() {
                                appSettings.shapeAmount = shapeAmountSlider.slider.value;
                            }
                        }
                    }
                }

                // Color control
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: appStyle.spacing

                    // Define brightness slider first so it's accessible
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Brightness"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        Slider {
                            id: brightnessSlider
                            Layout.fillWidth: true
                            from: 0.1
                            to: 0.9
                            value: 0.1
                            onValueChanged: appSettings.shapeBrightness = value
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Hue"
                            Layout.preferredWidth: 100
                            font.pixelSize: appStyle.fontSizeBody
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: "#FF0000"
                                }
                                GradientStop {
                                    position: 0.16
                                    color: "#FFFF00"
                                }
                                GradientStop {
                                    position: 0.33
                                    color: "#00FF00"
                                }
                                GradientStop {
                                    position: 0.5
                                    color: "#00FFFF"
                                }
                                GradientStop {
                                    position: 0.66
                                    color: "#0000FF"
                                }
                                GradientStop {
                                    position: 0.83
                                    color: "#FF00FF"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "#FF0000"
                                }
                            }

                            Slider {
                                id: hueSlider
                                anchors.fill: parent
                                from: 0
                                to: 1
                                value: 0.0 // red
                                background: Item {}
                                onValueChanged: appSettings.shapeHue = value
                            }

                            // saturation fixed at 70%
                            property color currentColor: Qt.hsla(hueSlider.value, 0.7, brightnessSlider.value, 1.0)
                            property var colorArray: [currentColor.r, currentColor.g, currentColor.b, 1.0]

                            UI.PortSource on colorArray {
                                port: processes.shape.color
                            }

                            Component.onCompleted: {
                                if (processes.shape.color) {
                                    Score.setValue(processes.shape.color, colorArray);
                                }
                            }

                            Connections {
                                target: hueSlider
                                function onValueChanged() {
                                    if (processes.shape.color) {
                                        var newColor = Qt.hsla(hueSlider.value, 0.7, brightnessSlider.value, 1.0);
                                        var newArray = [newColor.r, newColor.g, newColor.b, 1.0];
                                        Score.setValue(processes.shape.color, newArray);
                                    }
                                }
                            }

                            Connections {
                                target: brightnessSlider
                                function onValueChanged() {
                                    if (processes.shape.color) {
                                        var newColor = Qt.hsla(hueSlider.value, 0.7, brightnessSlider.value, 1.0);
                                        var newArray = [newColor.r, newColor.g, newColor.b, 1.0];
                                        Score.setValue(processes.shape.color, newArray);
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: appStyle.spacing
                    ParameterSlider {
                        id: shapeWidthSlider
                        Layout.fillWidth: true
                        labelText: "Width"
                        port: processes.shape.shapeWidth
                        from: 0
                        to: 2
                        initialValue: 0.5
                        onValueChanged: appSettings.shapeWidth = value
                    }
                    ParameterSlider {
                        id: shapeHeightSlider
                        Layout.fillWidth: true
                        labelText: "Height"
                        port: processes.shape.shapeHeight
                        from: 0
                        to: 2
                        initialValue: 0.5
                        onValueChanged: appSettings.shapeHeight = value
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: appStyle.spacing
                    ParameterSlider {
                        id: shapeHRepeatSlider
                        Layout.fillWidth: true
                        labelText: "H Repeat"
                        port: processes.shape.horizontalRepeat
                        from: 0
                        to: 10
                        initialValue: 1
                        stepSize: 1
                        onValueChanged: appSettings.shapeHRepeat = value
                    }
                    ParameterSlider {
                        id: shapeVRepeatSlider
                        Layout.fillWidth: true
                        labelText: "V Repeat"
                        port: processes.shape.verticalRepeat
                        from: 0
                        to: 10
                        initialValue: 1
                        stepSize: 1
                        onValueChanged: appSettings.shapeVRepeat = value
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    property int maxDimension: 512
                    property var arr: [shapex.value / maxDimension, shapey.value / maxDimension]
                    UI.PortSource on arr {
                        port: processes.shape.center
                    }

                    Label {
                        text: "X"
                        font.pixelSize: appStyle.fontSizeBody
                    }
                    SpinBox {
                        id: shapex
                        editable: true
                        Layout.fillWidth: true
                        from: 0
                        to: parent.maxDimension
                        value: parent.maxDimension / 2
                        font.pixelSize: appStyle.fontSizeBody
                        onValueChanged: {
                            if (processes.shape.center) {
                                var newArr = [value / parent.maxDimension, shapey.value / parent.maxDimension];
                                Score.setValue(processes.shape.center, newArr);
                            }
                            appSettings.shapeX = value;
                        }
                    }
                    Label {
                        text: "Y"
                        font.pixelSize: appStyle.fontSizeBody
                    }
                    SpinBox {
                        id: shapey
                        editable: true
                        Layout.fillWidth: true
                        from: 0
                        to: parent.maxDimension
                        value: parent.maxDimension / 2
                        font.pixelSize: appStyle.fontSizeBody
                        onValueChanged: {
                            if (processes.shape.center) {
                                var newArr = [shapex.value / parent.maxDimension, value / parent.maxDimension];
                                Score.setValue(processes.shape.center, newArr);
                            }
                            appSettings.shapeY = value;
                        }
                    }
                    CheckBox {
                        id: invertCheckBox
                        text: "Invert"
                        checked: false
                        font.pixelSize: appStyle.fontSizeBody
                        UI.PortSource on checked {
                            port: processes.shape.invertMask
                        }
                        Component.onCompleted: if (processes.shape.invertMask)
                            Score.setValue(processes.shape.invertMask, checked)
                        onCheckedChanged: {
                            if (processes.shape.invertMask)
                                Score.setValue(processes.shape.invertMask, checked);
                            appSettings.shapeInvert = checked;
                        }
                    }
                }
            }

        }
    }

    Rectangle {
        id: configToolbar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: toolbarRow.implicitHeight + appStyle.padding * 2
        color: appStyle.backgroundColor

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: appStyle.borderColor
        }

        RowLayout {
            id: toolbarRow
            anchors.fill: parent
            anchors.margins: appStyle.padding
            spacing: appStyle.spacing

            Button {
                text: isProcessing ? "Stop" : "Start"
                font.pixelSize: appStyle.fontSizeBody
                font.bold: true
                highlighted: isProcessing
                Layout.preferredWidth: 230
                enabled: isProcessing || (imagePathField.text !== "" && enginePathField.text !== "")
                onClicked: isProcessing = !isProcessing

                ToolTip.visible: !enabled && hovered
                ToolTip.text: imagePathField.text === "" && enginePathField.text === ""
                    ? "Set a video input path and an engine path (Advanced Options) before starting"
                    : imagePathField.text === ""
                        ? "Set a video input path before starting"
                        : "Set an engine path (Advanced Options) before starting"
                ToolTip.delay: 500
            }

            Label {
                id: configStatusLabel
                property bool isError: false
                Layout.fillWidth: true
                font.pixelSize: appStyle.fontSizeSmall
                color: isError ? "#FF3B30" : "#34C759"
                elide: Text.ElideMiddle
            }

            Button {
                text: "Open"
                font.pixelSize: appStyle.fontSizeBody
                onClicked: loadConfigDialog.open()
            }

            Button {
                text: "Save As"
                font.pixelSize: appStyle.fontSizeBody
                onClicked: saveConfigDialog.open()
            }
        }
    }

    Window {
        visible: mainView.visible
        title: "Input"
        width: sizeCombo.currentDimensions[0]
        height: sizeCombo.currentDimensions[1]
        CustomFrame {
            anchors.fill: parent
            process: "Video Mapper"
            port: 0
            showTexture: true

            StatusOverlay {
                sliders: [
                    {
                        name: "Video",
                        slider: imageAmountSlider.slider
                    },
                    {
                        name: "Camera",
                        slider: cameraAmountSlider.slider
                    },
                    {
                        name: "Smoke",
                        slider: smokeAmountSlider.slider
                    },
                    {
                        name: "Voronoi",
                        slider: voronoiAmountSlider.slider
                    },
                    {
                        name: "Noise",
                        slider: noiseAmountSlider.slider
                    },
                    {
                        name: "Perlin",
                        slider: perlinAmountSlider.slider
                    },
                    {
                        name: "Shape",
                        slider: shapeAmountSlider.slider
                    }
                ]
            }
        }
    }
    Window {
        visible: mainView.visible
        title: "Preview"
        width: sizeCombo.currentDimensions[0]
        height: sizeCombo.currentDimensions[1]
        CustomFrame {
            anchors.fill: parent
            process: "Video Mapper.1"
            port: 0
            showTexture: true
        }
    }

    // CONFIG FILE DIALOGS
 
    FileDialog {
        id: saveConfigDialog
        title: "Save Configuration"
        nameFilters: ["Koaia Config Files (*.koaia)", "JSON Files (*.json)", "All Files (*)"]
        fileMode: FileDialog.SaveFile
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            var fileUrl = selectedFile.toString()
            if (!fileUrl.endsWith(".koaia") && !fileUrl.endsWith(".json"))
                fileUrl = fileUrl + ".koaia"
            doSave(fileUrl)
        }
    }

    FileDialog {
        id: loadConfigDialog
        title: "Load Configuration"
        nameFilters: ["Koaia Config Files (*.koaia)", "JSON Files (*.json)", "All Files (*)"]
        fileMode: FileDialog.OpenFile
        currentFolder: Qt.resolvedUrl("../../presets/")
        onAccepted: {
            loadConfigFromUrl(selectedFile, false);
        }
    }
}
