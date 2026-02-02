import QtCore
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Score.UI as UI
import koaia

Pane {
    id: mainView
    
    property bool isProcessing: false
    onIsProcessingChanged: (isProcessing)? Score.play() : Score.stop()
    
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
        property int guidanceType: 0
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

        // Shape layer section
        property int shapeType: 1
        property real shapeAmount: 0.0
        property real shapeBrightness: 0.1
        property real shapeHue: 0.0
        property int shapeX: 256
        property int shapeY: 256
        property bool shapeInvert: false
    }

    Component.onCompleted: {
        restoreSavedSettings()
    }

    function restoreSavedSettings() {
        // Input section
        imagePathField.text = appSettings.videoPath
        imageAmountSlider.slider.value = appSettings.videoAmount
        cameraAmountSlider.slider.value = appSettings.cameraAmount

        // AI Model section
        promptTextField.text = appSettings.prompt
        workflowCombo.currentIndex = appSettings.workflow
        enginePathField.text = appSettings.enginePath
        seedSpinBox.value = appSettings.seed
        timestepsField.text = appSettings.timesteps
        guidanceTypeCombo.currentIndex = appSettings.guidanceType
        denoisingBatchSpinBox.checked = appSettings.denoisingBatch
        addNoiseCheckBox.checked = appSettings.addNoise
        manualModeCheckBox.checked = appSettings.manualMode
        sizeCombo.currentIndex = appSettings.resolution

        // Noise layer section
        inputNoiseChooser.currentIndex = appSettings.noiseShader
        smokeAmountSlider.slider.value = appSettings.smokeAmount
        voronoiAmountSlider.slider.value = appSettings.voronoiAmount
        noiseAmountSlider.slider.value = appSettings.noiseAmount
        perlinAmountSlider.slider.value = appSettings.perlinAmount

        // Shape layer section
        shapeTypeCombo.currentIndex = appSettings.shapeType
        shapeAmountSlider.slider.value = appSettings.shapeAmount
        brightnessSlider.value = appSettings.shapeBrightness
        hueSlider.value = appSettings.shapeHue
        shapex.value = appSettings.shapeX
        shapey.value = appSettings.shapeY
        invertCheckBox.checked = appSettings.shapeInvert
    }
    
    // Score process objects
    ProcessObjects {
        id: processes
    }

    component Section : ColumnLayout {
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
            anchors.fill: parent
            anchors.margins: appStyle.padding
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
                                appSettings.videoPath = text
                                if (videoProcess && text !== "") {
                                    console.log("Setting video path to:", text)
                                    var wasPlaying = isProcessing
                                    if (wasPlaying) {
                                        console.log("Stopping Score to reload video...")
                                        Score.stop()
                                        isProcessing = false
                                    }

                                    videoProcess.path = text

                                    if (wasPlaying) {
                                        Qt.callLater(function() {
                                            console.log("Restarting Score with new video...")
                                            isProcessing = true
                                            Score.play()
                                        })
                                    }
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
                        nameFilters: [
                            "Video Files (*.mp4 *.avi *.mov *.mkv *.webm *.flv)"
                        ]
                        onAccepted: {
                            if (!selectedFile) {
                                console.log("No file selected")
                                return
                            }
                            var filePath = new URL(selectedFile).pathname.substr(Qt.platform.os === "windows" ? 1 : 0);
                            imagePathField.text = filePath
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: appStyle.spacing
                    AmountSlider {
                        id: imageAmountSlider
                            Layout.fillWidth: true
                            label: "Video"
                            value: imagePathField.text !== "" ? (imageAmountSlider.slider.value || 0.8) : 0.0
                            port: processes.video_Mixer.alpha7
                            enabled: imagePathField.text !== ""

                            Connections {
                                target: imagePathField
                                function onTextChanged() {
                                    if (imagePathField.text === "") {
                                        imageAmountSlider.slider.value = 0.0
                                    }
                                }
                            }
                            Connections {
                                target: imageAmountSlider.slider
                                function onValueChanged() { appSettings.videoAmount = imageAmountSlider.slider.value }
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
                                function onValueChanged() { appSettings.cameraAmount = cameraAmountSlider.slider.value }
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
                }

                Section {
                    id: aiModelSection
                    title: "AI model"
                    description: "Configure AI image generation parameters including prompts, seed, and steps"

                    property bool showAdvancedOptions: false

                    Label { text: "Prompt"; font.pixelSize: appStyle.fontSizeBody }

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
                        UI.PortSource on text { port: processes.prompt_composer.keywords }
                        Component.onCompleted: if (processes.prompt_composer.keywords) Score.setValue(processes.prompt_composer.keywords, text)
                        onTextChanged: {
                            if (processes.prompt_composer.keywords) Score.setValue(processes.prompt_composer.keywords, text)
                            appSettings.prompt = text
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
                            Label { text: "Workflow"; Layout.preferredWidth: 100; font.pixelSize: appStyle.fontSizeBody }
                            ComboBox {
                                id: workflowCombo
                                Layout.fillWidth: true
                                model: ["SD_TXT2IMG", "SD_IMG2IMG", "SD_TXT2IMG_CONTROLNET", "SD_TXT2IMG_IPADAPTER", "SD_IMG2IMG_IPADAPTER", "STURBO_TXT2IMG", "SDTURBO_IMG2IMG", "SDXL_TXT2IMG", "SDXL_IMG2IMG", "V2V_TXT2IMG", "V2V_IMG2IMG"]
                                currentIndex: 0
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on currentIndex { port: processes.streamDiffusion.workflow }
                                Component.onCompleted: if (processes.streamDiffusion.workflow) Score.setValue(processes.streamDiffusion.workflow, currentIndex)
                                onCurrentIndexChanged: {
                                    if (processes.streamDiffusion.workflow) Score.setValue(processes.streamDiffusion.workflow, currentIndex)
                                    appSettings.workflow = currentIndex
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Engine"; Layout.preferredWidth: 100; font.pixelSize: appStyle.fontSizeBody }
                            TextField {
                                id: enginePathField
                                Layout.fillWidth: true
                                font.pixelSize: appStyle.fontSizeBody
                                text: ""
                                placeholderText: "Path to engine folder"
                                UI.PortSource on text { port: processes.streamDiffusion.engines }
                                Component.onCompleted: if (processes.streamDiffusion.engines) Score.setValue(processes.streamDiffusion.engines, text)
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

                        FolderDialog {
                            id: engineFolderDialog
                            title: "Select Engine Folder"
                            onAccepted: {
                                if (!selectedFolder) {
                                    console.log("No folder selected")
                                    return
                                }
                                var folderPath = new URL(selectedFolder).pathname.substr(Qt.platform.os === "windows" ? 1 : 0);
                                enginePathField.text = folderPath
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
                            Label { text: "Seed"; font.pixelSize: appStyle.fontSizeBody }
                            SpinBox {
                                id: seedSpinBox
                                Layout.fillWidth: true
                                from: 0; to: 9999999; value: 20; stepSize: 1
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on value { port: processes.streamDiffusion.seed }
                                Component.onCompleted: if (processes.streamDiffusion.seed) Score.setValue(processes.streamDiffusion.seed, value)
                                onValueChanged: {
                                    if (processes.streamDiffusion.seed) Score.setValue(processes.streamDiffusion.seed, value)
                                    appSettings.seed = value
                                }
                            }
                            Label { text: "Timesteps"; font.pixelSize: appStyle.fontSizeBody }
                            TextField {
                                id: timestepsField
                                Layout.fillWidth: true
                                text: "20"
                                placeholderText: "e.g. 20 or 30,45"
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on text { port: processes.streamDiffusion.timesteps }
                                Component.onCompleted: if (processes.streamDiffusion.timesteps) Score.setValue(processes.streamDiffusion.timesteps, text)
                                onTextChanged: {
                                    if (processes.streamDiffusion.timesteps) Score.setValue(processes.streamDiffusion.timesteps, text)
                                    appSettings.timesteps = text
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Guidance"; font.pixelSize: appStyle.fontSizeBody }
                            ParameterSlider {
                                Layout.fillWidth: true
                                labelText: ""
                                port: processes.streamDiffusion.guidance
                                from: 0
                                to: 20
                                initialValue: 1.0
                            }
                            Label { text: "Guidance type"; font.pixelSize: appStyle.fontSizeBody }
                            ComboBox {
                                id: guidanceTypeCombo
                                Layout.fillWidth: true
                                model: ["None", "Self", "Full", "Initialize"]
                                currentIndex: 0
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on currentIndex { port: processes.streamDiffusion.guidance_type }
                                Component.onCompleted: if (processes.streamDiffusion.guidance_type) Score.setValue(processes.streamDiffusion.guidance_type, currentIndex)
                                onCurrentIndexChanged: {
                                    if (processes.streamDiffusion.guidance_type) Score.setValue(processes.streamDiffusion.guidance_type, currentIndex)
                                    appSettings.guidanceType = currentIndex
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Delta"; font.pixelSize: appStyle.fontSizeBody }
                            ParameterSlider {
                                Layout.fillWidth: true
                                labelText: ""
                                port: processes.streamDiffusion.delta
                                from: 0
                                to: 2
                                initialValue: 1.0
                                stepSize: 0.01
                            }
                        }


                        RowLayout {
                            Layout.fillWidth: true
                            CheckBox {
                                id: denoisingBatchSpinBox
                                text: "Denoise Batch"
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on checked { port: processes.streamDiffusion.denoising_batch }
                                Component.onCompleted: if (processes.streamDiffusion.denoising_batch) Score.setValue(processes.streamDiffusion.denoising_batch, checked)
                                onCheckedChanged: {
                                    if (processes.streamDiffusion.denoising_batch) Score.setValue(processes.streamDiffusion.denoising_batch, checked)
                                    appSettings.denoisingBatch = checked
                                }
                            }
                            CheckBox {
                                id: addNoiseCheckBox
                                text: "Add Noise"
                                checked: false
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on checked { port: processes.streamDiffusion.add_noise }
                                Component.onCompleted: if (processes.streamDiffusion.add_noise) Score.setValue(processes.streamDiffusion.add_noise, checked)
                                onCheckedChanged: {
                                    if (processes.streamDiffusion.add_noise) Score.setValue(processes.streamDiffusion.add_noise, checked)
                                    appSettings.addNoise = checked
                                }
                            }
                            CheckBox {
                                id: manualModeCheckBox
                                text: "Manual Mode"
                                checked: false
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on checked { port: processes.streamDiffusion.manual_mode }
                                Component.onCompleted: if (processes.streamDiffusion.manual_mode) Score.setValue(processes.streamDiffusion.manual_mode, checked)
                                onCheckedChanged: {
                                    if (processes.streamDiffusion.manual_mode) Score.setValue(processes.streamDiffusion.manual_mode, checked)
                                    appSettings.manualMode = checked
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Resolution"; font.pixelSize: appStyle.fontSizeBody }
                            ComboBox {
                                id: sizeCombo
                                Layout.fillWidth: true
                                model: ["512 x 512", "1024 x 1024"]
                                property int baseSize: 512
                                property int currentDimension: baseSize
                                property var currentDimensions: [currentDimension, currentDimension]
                                onCurrentIndexChanged: {
                                    currentDimension = baseSize * (currentIndex + 1)
                                    appSettings.resolution = currentIndex
                                }
                                UI.PortSource on currentDimensions { port: processes.streamDiffusion.resolution }
                                Component.onCompleted: if (processes.streamDiffusion.resolution) Score.setValue(processes.streamDiffusion.resolution, currentDimensions)
                                onCurrentDimensionsChanged: if (processes.streamDiffusion.resolution) Score.setValue(processes.streamDiffusion.resolution, currentDimensions)
                            }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.topMargin: appStyle.spacing
                    Layout.bottomMargin: appStyle.spacing
                    text: isProcessing ? "Stop" : "Start"
                    font.pixelSize: appStyle.fontSizeBody
                    font.bold: true
                    highlighted: isProcessing
                    onClicked: isProcessing = !isProcessing
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
                                function onValueChanged() { appSettings.smokeAmount = smokeAmountSlider.slider.value }
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
                                function onValueChanged() { appSettings.voronoiAmount = voronoiAmountSlider.slider.value }
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
                                function onValueChanged() { appSettings.noiseAmount = noiseAmountSlider.slider.value }
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
                                function onValueChanged() { appSettings.perlinAmount = perlinAmountSlider.slider.value }
                            }
                        }
                    }

                    ShaderControls {
                        Layout.fillWidth: true
                        shaderType: inputNoiseChooser.currentIndex
                        voronoi: processes.voronoi
                        perlin_Noise: processes.perlin_Noise
                        white_Noise: processes.white_Noise
                        simplex_Noise: processes.simplex_Noise
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
                            UI.PortSource on currentIndex { port: processes.shape.maskShapeMode }
                            Component.onCompleted: if (processes.shape.maskShapeMode) Score.setValue(processes.shape.maskShapeMode, currentIndex)
                            onCurrentIndexChanged: {
                                if (processes.shape.maskShapeMode) Score.setValue(processes.shape.maskShapeMode, currentIndex)
                                appSettings.shapeType = currentIndex
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
                                function onValueChanged() { appSettings.shapeAmount = shapeAmountSlider.slider.value }
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
                            Label { text: "Brightness"; Layout.preferredWidth: 100; font.pixelSize: appStyle.fontSizeBody }
                            Slider {
                                id: brightnessSlider
                                Layout.fillWidth: true
                                from: 0.1; to: 0.9; value: 0.1
                                onValueChanged: appSettings.shapeBrightness = value
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Hue"; Layout.preferredWidth: 100; font.pixelSize: appStyle.fontSizeBody }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
                                radius: 3
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#FF0000" }
                                    GradientStop { position: 0.16; color: "#FFFF00" }
                                    GradientStop { position: 0.33; color: "#00FF00" }
                                    GradientStop { position: 0.5; color: "#00FFFF" }
                                    GradientStop { position: 0.66; color: "#0000FF" }
                                    GradientStop { position: 0.83; color: "#FF00FF" }
                                    GradientStop { position: 1.0; color: "#FF0000" }
                                }
                                
                                Slider {
                                    id: hueSlider
                                    anchors.fill: parent
                                    from: 0; to: 1; value: 0.0 // red
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
                                        Score.setValue(processes.shape.color, colorArray)
                                    }
                                }
                                
                                Connections {
                                    target: hueSlider
                                    function onValueChanged() {
                                        if (processes.shape.color) {
                                            var newColor = Qt.hsla(hueSlider.value, 0.7, brightnessSlider.value, 1.0)
                                            var newArray = [newColor.r, newColor.g, newColor.b, 1.0]
                                            Score.setValue(processes.shape.color, newArray)
                                        }
                                    }
                                }
                                
                                Connections {
                                    target: brightnessSlider
                                    function onValueChanged() {
                                        if (processes.shape.color) {
                                            var newColor = Qt.hsla(hueSlider.value, 0.7, brightnessSlider.value, 1.0)
                                            var newArray = [newColor.r, newColor.g, newColor.b, 1.0]
                                            Score.setValue(processes.shape.color, newArray)
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
                            Layout.fillWidth: true
                            labelText: "Width"
                            port: processes.shape.shapeWidth
                            from: 0
                            to: 2
                            initialValue: 0.5
                        }
                        ParameterSlider {
                            Layout.fillWidth: true
                            labelText: "Height"
                            port: processes.shape.shapeHeight
                            from: 0
                            to: 2
                            initialValue: 0.5
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: appStyle.spacing
                        ParameterSlider {
                            Layout.fillWidth: true
                            labelText: "H Repeat"
                            port: processes.shape.horizontalRepeat
                            from: 0
                            to: 10
                            initialValue: 1
                            stepSize: 1
                        }
                        ParameterSlider {
                            Layout.fillWidth: true
                            labelText: "V Repeat"
                            port: processes.shape.verticalRepeat
                            from: 0
                            to: 10
                            initialValue: 1
                            stepSize: 1
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        property int maxDimension: 512
                        property var arr: [shapex.value / maxDimension, shapey.value / maxDimension]
                        UI.PortSource on arr { port: processes.shape.center }

                        Label { text: "X"; font.pixelSize: appStyle.fontSizeBody }
                        SpinBox {
                            id: shapex
                            Layout.fillWidth: true
                            from: 0
                            to: parent.maxDimension
                            value: parent.maxDimension / 2
                            editable: true
                            font.pixelSize: appStyle.fontSizeBody
                            onValueChanged: {
                                if (processes.shape.center) {
                                    var newArr = [value / parent.maxDimension, shapey.value / parent.maxDimension]
                                    Score.setValue(processes.shape.center, newArr)
                                }
                                appSettings.shapeX = value
                            }
                        }
                        Label { text: "Y"; font.pixelSize: appStyle.fontSizeBody }
                        SpinBox {
                            id: shapey
                            Layout.fillWidth: true
                            from: 0
                            to: parent.maxDimension
                            value: parent.maxDimension / 2
                            editable: true
                            font.pixelSize: appStyle.fontSizeBody
                            onValueChanged: {
                                if (processes.shape.center) {
                                    var newArr = [shapex.value / parent.maxDimension, value / parent.maxDimension]
                                    Score.setValue(processes.shape.center, newArr)
                                }
                                appSettings.shapeY = value
                            }
                        }
                        CheckBox {
                            id: invertCheckBox
                            text: "Invert"
                            checked: false
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on checked { port: processes.shape.invertMask }
                            Component.onCompleted: if (processes.shape.invertMask) Score.setValue(processes.shape.invertMask, checked)
                            onCheckedChanged: {
                                if (processes.shape.invertMask) Score.setValue(processes.shape.invertMask, checked)
                                appSettings.shapeInvert = checked
                            }
                        }
                    }
                }

               // Section {
                //     title: "Presets"
                //     description: "Save and load preset configurations for quick setup"

                //     RowLayout {
                //         Layout.fillWidth: true
                //         spacing: appStyle.spacing

                //         Button { text: "Load preset"; font.pixelSize: appStyle.fontSizeBody }

                //         Button { text: "Capture current state"; font.pixelSize: appStyle.fontSizeBody }
                //     }
                // }

                // little bottom padding?
                Item { height: appStyle.padding }
            }
        }


    Window {
        visible: mainView.visible
        title: "Input"
        width: sizeCombo.currentDimensions[0]
        height: sizeCombo.currentDimensions[1]
        CustomFrame {
            anchors.fill:  parent
            process: "Video Mapper"
            port: 0
            showTexture: true

            StatusOverlay {
                sliders: [
                    {name: "Video", slider: imageAmountSlider.slider},
                    {name: "Camera", slider: cameraAmountSlider.slider},
                    {name: "Smoke", slider: smokeAmountSlider.slider},
                    {name: "Voronoi", slider: voronoiAmountSlider.slider},
                    {name: "Noise", slider: noiseAmountSlider.slider},
                    {name: "Perlin", slider: perlinAmountSlider.slider},
                    {name: "Shape", slider: shapeAmountSlider.slider}
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
            anchors.fill:  parent
            process: "Video Mapper.1"
            port: 0
            showTexture: true
        }
    }
}
