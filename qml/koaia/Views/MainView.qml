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
                        }
                        AmountSlider {
                            id: cameraAmountSlider
                            Layout.fillWidth: true
                            label: "Camera"
                            value: 0.0
                            port: processes.video_Mixer.alpha8
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
                        onTextChanged: if (processes.prompt_composer.keywords) Score.setValue(processes.prompt_composer.keywords, text)
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

                        Label { text: "Parameters"; font.pixelSize: appStyle.fontSizeBody }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Seed"; font.pixelSize: appStyle.fontSizeBody }
                            SpinBox {
                                Layout.fillWidth: true
                                from: 0; to: 9999999; value: 100; stepSize: 1
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on value { port: processes.streamDiffusion_img2img.seed }
                                Component.onCompleted: if (processes.streamDiffusion_img2img.seed) Score.setValue(processes.streamDiffusion_img2img.seed, value)
                                onValueChanged: if (processes.streamDiffusion_img2img.seed) Score.setValue(processes.streamDiffusion_img2img.seed, value)
                            }
                            Label { text: "Steps"; font.pixelSize: appStyle.fontSizeBody }
                            SpinBox {
                                Layout.fillWidth: true
                                from: 1; to: 100; value: 35; stepSize: 1
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on value { port: processes.streamDiffusion_img2img.steps }
                                Component.onCompleted: if (processes.streamDiffusion_img2img.steps) Score.setValue(processes.streamDiffusion_img2img.steps, value)
                                onValueChanged: if (processes.streamDiffusion_img2img.steps) Score.setValue(processes.streamDiffusion_img2img.steps, value)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Guidance"; font.pixelSize: appStyle.fontSizeBody }
                            ParameterSlider {
                                Layout.fillWidth: true
                                labelText: ""
                                port: processes.streamDiffusion_img2img.guidance
                                from: 0
                                to: 20
                                initialValue: 7.5
                            }
                            Label { text: "CFG"; font.pixelSize: appStyle.fontSizeBody }
                            ParameterSlider {
                                Layout.fillWidth: true
                                labelText: ""
                                port: processes.streamDiffusion_img2img.cfg
                                from: 0
                                to: 20
                                initialValue: 1.0
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "T1"; font.pixelSize: appStyle.fontSizeBody }
                            ParameterSlider {
                                Layout.fillWidth: true
                                labelText: ""
                                port: processes.streamDiffusion_img2img.t1
                                from: 0
                                to: 100
                                initialValue: 50
                            }
                            Label { text: "T2"; font.pixelSize: appStyle.fontSizeBody }
                            ParameterSlider {
                                Layout.fillWidth: true
                                labelText: ""
                                port: processes.streamDiffusion_img2img.t2
                                from: 0
                                to: 100
                                initialValue: 50
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "T Count"; font.pixelSize: appStyle.fontSizeBody }
                            SpinBox {
                                Layout.fillWidth: true
                                from: 1; to: 100; value: 1; stepSize: 1
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on value { port: processes.streamDiffusion_img2img.t_count }
                                Component.onCompleted: if (processes.streamDiffusion_img2img.t_count) Score.setValue(processes.streamDiffusion_img2img.t_count, value)
                                onValueChanged: if (processes.streamDiffusion_img2img.t_count) Score.setValue(processes.streamDiffusion_img2img.t_count, value)
                            }
                            Label { text: "Denoise Batch"; font.pixelSize: appStyle.fontSizeBody }
                            SpinBox {
                                Layout.fillWidth: true
                                from: 1; to: 100; value: 1; stepSize: 1
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on value { port: processes.streamDiffusion_img2img.denoising_batch }
                                Component.onCompleted: if (processes.streamDiffusion_img2img.denoising_batch) Score.setValue(processes.streamDiffusion_img2img.denoising_batch, value)
                                onValueChanged: if (processes.streamDiffusion_img2img.denoising_batch) Score.setValue(processes.streamDiffusion_img2img.denoising_batch, value)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            CheckBox {
                                text: "Add Noise"
                                checked: false
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on checked { port: processes.streamDiffusion_img2img.add_noise }
                                Component.onCompleted: if (processes.streamDiffusion_img2img.add_noise) Score.setValue(processes.streamDiffusion_img2img.add_noise, checked)
                                onCheckedChanged: if (processes.streamDiffusion_img2img.add_noise) Score.setValue(processes.streamDiffusion_img2img.add_noise, checked)
                            }
                            CheckBox {
                                text: "Manual Mode"
                                checked: false
                                font.pixelSize: appStyle.fontSizeBody
                                UI.PortSource on checked { port: processes.streamDiffusion_img2img.manual_mode }
                                Component.onCompleted: if (processes.streamDiffusion_img2img.manual_mode) Score.setValue(processes.streamDiffusion_img2img.manual_mode, checked)
                                onCheckedChanged: if (processes.streamDiffusion_img2img.manual_mode) Score.setValue(processes.streamDiffusion_img2img.manual_mode, checked)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Size"; font.pixelSize: appStyle.fontSizeBody }
                            ComboBox {
                                id: sizeCombo
                                Layout.fillWidth: true
                                model: ["512 x 512", "1024 x 1024"]
                                property int baseSize: 512
                                property int currentDimension: baseSize
                                property var currentDimensions: [currentDimension, currentDimension]
                                onCurrentIndexChanged: currentDimension = baseSize * (currentIndex + 1)
                                UI.PortSource on currentDimensions { port: processes.streamDiffusion_img2img.size }
                                Component.onCompleted: if (processes.streamDiffusion_img2img.size) Score.setValue(processes.streamDiffusion_img2img.size, currentDimensions)
                                onCurrentDimensionsChanged: if (processes.streamDiffusion_img2img.size) Score.setValue(processes.streamDiffusion_img2img.size, currentDimensions)
                            }
                        }
                    }
                }

                Section {
                    title: "Layering"
                    description: "Control shader effects, noise patterns, and shape masks for compositing layers"

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
                        }
                        // Amount sliders (check in StatusOverlay)
                        AmountSlider {
                            id: smokeAmountSlider
                            Layout.fillWidth: true
                            label: "Amount"
                            value: 0.0
                            port: processes.video_Mixer.alpha2
                            visible: inputNoiseChooser.currentIndex === 0
                        }
                        AmountSlider {
                            id: voronoiAmountSlider
                            Layout.fillWidth: true
                            label: "Amount"
                            value: 0.0
                            port: processes.video_Mixer.alpha3
                            visible: inputNoiseChooser.currentIndex === 1
                        }
                        AmountSlider {
                            id: noiseAmountSlider
                            Layout.fillWidth: true
                            label: "Amount"
                            value: 0.0
                            port: processes.video_Mixer.alpha4
                            visible: inputNoiseChooser.currentIndex === 2
                        }
                        AmountSlider {
                            id: perlinAmountSlider
                            Layout.fillWidth: true
                            label: "Amount"
                            value: 0.0
                            port: processes.video_Mixer.alpha5
                            visible: inputNoiseChooser.currentIndex === 3
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
                            onCurrentIndexChanged: if (processes.shape.maskShapeMode) Score.setValue(processes.shape.maskShapeMode, currentIndex)
                        }
                        AmountSlider {
                            id: shapeAmountSlider
                            Layout.fillWidth: true
                            label: "Amount"
                            value: 0.0
                            port: processes.video_Mixer.alpha1
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
                            }
                        }
                        CheckBox {
                            id: invertCheckBox
                            text: "Invert"
                            checked: false
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on checked { port: processes.shape.invertMask }
                            Component.onCompleted: if (processes.shape.invertMask) Score.setValue(processes.shape.invertMask, checked)
                            onCheckedChanged: if (processes.shape.invertMask) Score.setValue(processes.shape.invertMask, checked)
                        }
                    }
                }

                Section {
                    title: "Presets"
                    description: "Save and load preset configurations for quick setup"

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: appStyle.spacing

                        Button { text: "Load preset"; font.pixelSize: appStyle.fontSizeBody }

                        Button {
                            text: "Capture current state"
                            font.pixelSize: appStyle.fontSizeBody
                            onClicked: {
                                mainView.grabToImage(function(result) {
                                    if (result.saveToFile) {
                                        // Use saveToFile if available (Qt 6.5+)
                                        result.saveToFile("capture.png")
                                    } else {
                                        // Fallback for older Qt versions
                                        result.save("capture.png")
                                    }
                                })
                            }
                        }
                    }
                }

                // little bottom padding?
                Item { height: appStyle.padding }
            }
        }


    Window {
        visible: true
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
        visible: true
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
