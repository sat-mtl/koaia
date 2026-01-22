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

    RowLayout {
        anchors.fill: parent
        anchors.margins: appStyle.padding
        spacing: appStyle.spacing

        ScrollView {
            id: leftScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                            UI.PortSource on text { 
                                port: processes.images_19.images
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
                        title: "Select Image or Video File"
                        nameFilters: [
                            "Image Files (*.jpg *.jpeg *.png *.gif *.bmp)",
                            "Video Files (*.mp4 *.avi *.mov *.mkv)",
                            "All Files (*)"
                        ]
                        onAccepted: {
                            var filePath = selectedFile.toString()
                            // Cross-platform file path handling
                            if (filePath.startsWith("file://")) {
                                filePath = filePath.substring(7)
                            }
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
                    title: "Layering"
                    description: "Control shader effects, noise patterns, and shape masks for compositing layers"

                    // Shader
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: appStyle.spacing
                        Label { 
                            text: "Shader"
                            Layout.preferredWidth: 50
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
                            value: 0.6
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
                        Layout.fillWidth: true
                        model: ["Rectangle", "Triangle", "Circle", "Diamond"]
                        currentIndex: 1
                        font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on currentIndex { port: processes.shape.maskShapeMode }
                            Component.onCompleted: if (processes.shape.maskShapeMode) Score.setValue(processes.shape.maskShapeMode, currentIndex)
                        }
                        CheckBox {
                            id: invertCheckBox
                            text: "Invert"
                            checked: false
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on checked { port: processes.shape.invertMask }
                            Component.onCompleted: if (processes.shape.invertMask) Score.setValue(processes.shape.invertMask, checked)
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
                        }
                    }


                    AmountSlider {
                        id: shapeAmountSlider
                        label: "Amount"
                        value: 0.5
                        port: processes.video_Mixer.alpha1
                    }
                }

                Section {
                    title: "AI model"
                    description: "Configure AI image generation parameters including prompts, seed, and steps"

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
                        }
                        Label { text: "Steps"; font.pixelSize: appStyle.fontSizeBody }
                        SpinBox {
                            Layout.fillWidth: true
                            from: 1; to: 100; value: 35; stepSize: 1
                            font.pixelSize: appStyle.fontSizeBody
                            UI.PortSource on value { port: processes.streamDiffusion_img2img.steps }
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
                        }
                    }
                }

                Section {
                    title: "Output stream"
                    description: "Set output resolution, frame rate, format, and stream name"

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: appStyle.spacing
                        columnSpacing: appStyle.spacing

                        Label { text: "Width"; font.pixelSize: appStyle.fontSizeBody }
                        SpinBox { Layout.fillWidth: true; from: 320; to: 4096; value: 1280; stepSize: 32; font.pixelSize: appStyle.fontSizeBody }
                        Label { text: "Height"; font.pixelSize: appStyle.fontSizeBody }
                        SpinBox { Layout.fillWidth: true; from: 240; to: 2160; value: 720; stepSize: 32; font.pixelSize: appStyle.fontSizeBody }

                        Label { text: "Rate fps"; font.pixelSize: appStyle.fontSizeBody }
                        SpinBox { Layout.fillWidth: true; from: 1; to: 120; value: 60; stepSize: 1; font.pixelSize: appStyle.fontSizeBody }
                        Label { text: "Format"; font.pixelSize: appStyle.fontSizeBody }
                        ComboBox { model: ["RGBA", "RGB", "YUV"]; currentIndex: 0; Layout.fillWidth: true; font.pixelSize: appStyle.fontSizeBody }

                        Label { text: "Name"; font.pixelSize: appStyle.fontSizeBody }
                        TextField {
                            text: "streamdiffusion_2"
                            Layout.columnSpan: 3
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            placeholderText: "streamdiffusion_2"
                        }

                        Button {
                            text: isProcessing ? "Stop" : "Start"
                            Layout.columnSpan: 4
                            Layout.fillWidth: true
                            font.pixelSize: appStyle.fontSizeBody
                            font.bold: true
                            highlighted: isProcessing
                            onClicked: isProcessing = !isProcessing
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

        ColumnLayout {
            id: rightPreview
            Layout.fillHeight: true
            spacing: 8

            CustomFrame {
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

            CustomFrame {
                process: "Video Mapper.1"
                port: 0
                showTexture: true
            }
        }
    }
}
