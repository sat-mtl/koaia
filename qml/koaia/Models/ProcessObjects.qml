import QtQuick

QtObject {
    id: root

    property QtObject genai: QtObject {
        property var process_object: Score.find("genai")
    }

    // Image input
    property QtObject images_19: QtObject {
        property var process_object: Score.find("Images.19")
        property var index: Score.inlet(process_object, 0)
        property var opacity: Score.inlet(process_object, 1)
        property var position: Score.inlet(process_object, 2)
        property var scale_X: Score.inlet(process_object, 3)
        property var scale_Y: Score.inlet(process_object, 4)
        property var images: Score.inlet(process_object, 5)
        property var tile: Score.inlet(process_object, 6)
        property var scale: Score.inlet(process_object, 7)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // Shape
    property QtObject shape: QtObject {
        property var process_object: Score.find("Basic Shape")
        property var color: Score.inlet(process_object, 0)
        property var maskShapeMode: Score.inlet(process_object, 1)
        property var shapeWidth: Score.inlet(process_object, 2)
        property var shapeHeight: Score.inlet(process_object, 3)
        property var center: Score.inlet(process_object, 4)
        property var invertMask: Score.inlet(process_object, 5)
        property var horizontalRepeat: Score.inlet(process_object, 6)
        property var verticalRepeat: Score.inlet(process_object, 7)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // Smoke
    property QtObject smoke: QtObject {
        property var process_object: Score.find("Smoke")
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // Voronoi
    property QtObject voronoi: QtObject {
        property var process_object: Score.find("Voronoi")
        property var seed: Score.inlet(process_object, 0)
        property var iregularity: Score.inlet(process_object, 1)
        property var blur: Score.inlet(process_object, 2)
        property var scale: Score.inlet(process_object, 3)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // White Noise
    property QtObject white_Noise: QtObject {
        property var process_object: Score.find("White Noise")
        property var seed: Score.inlet(process_object, 0)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // Perlin Noise
    property QtObject perlin_Noise: QtObject {
        property var process_object: Score.find("Perlin Noise")
        property var seed: Score.inlet(process_object, 0)
        property var scale: Score.inlet(process_object, 1)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // Simplex Noise
    property QtObject simplex_Noise: QtObject {
        property var process_object: Score.find("Simplex Noise")
        property var offset: Score.inlet(process_object, 0)
        property var scale: Score.inlet(process_object, 1)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // Video Mixer
    property QtObject video_Mixer: QtObject {
        property var process_object: Score.find("Video Mixer")
        property var alpha1: Score.inlet(process_object, 8)
        property var alpha2: Score.inlet(process_object, 9)
        property var alpha3: Score.inlet(process_object, 10)
        property var alpha4: Score.inlet(process_object, 11)
        property var alpha5: Score.inlet(process_object, 12)
        property var alpha6: Score.inlet(process_object, 13)
        property var alpha7: Score.inlet(process_object, 14)
        property var alpha8: Score.inlet(process_object, 15)
        property var mode1: Score.inlet(process_object, 16)
        property var mode2: Score.inlet(process_object, 17)
        property var mode3: Score.inlet(process_object, 18)
        property var mode4: Score.inlet(process_object, 19)
        property var mode5: Score.inlet(process_object, 20)
        property var mode6: Score.inlet(process_object, 21)
        property var mode7: Score.inlet(process_object, 22)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // StreamDiffusion
    property QtObject streamDiffusion_img2img: QtObject {
        property var process_object: Score.find("StreamDiffusion img2img")
        property var prompt__: Score.inlet(process_object, 1)
        property var model: Score.inlet(process_object, 3)
        property var loRAs: Score.inlet(process_object, 4)
        property var vAE: Score.inlet(process_object, 5)
        property var seed: Score.inlet(process_object, 6)
        property var steps: Score.inlet(process_object, 7)
        property var guidance: Score.inlet(process_object, 8)
        property var t1: Score.inlet(process_object, 9)
        property var t2: Score.inlet(process_object, 10)
        property var t_count: Score.inlet(process_object, 11)
        property var size: Score.inlet(process_object, 12)
        property var cfg: Score.inlet(process_object, 13)
        property var add_noise: Score.inlet(process_object, 14)
        property var denoising_batch: Score.inlet(process_object, 15)
        property var manual_mode: Score.inlet(process_object, 16)
        property var manual_trigger: Score.inlet(process_object, 17)
        property var out: Score.outlet(process_object, 0)
    }

    // Prompt Composer
    property QtObject prompt_composer: QtObject {
        property var process_object: Score.find("Prompt composer")
        property var keywords: Score.inlet(process_object, 0)
        property var weights: Score.inlet(process_object, 1)
        property var input_0: Score.inlet(process_object, 2)
        property var output: Score.outlet(process_object, 0)
    }

    // Video Mapper
    property QtObject video_Mapper: QtObject {
        property var process_object: Score.find("Video Mapper")
        property var _c_identifier: Score.inlet(process_object, 0)
        property var topleft: Score.inlet(process_object, 1)
        property var bottomleft: Score.inlet(process_object, 2)
        property var topright: Score.inlet(process_object, 3)
        property var bottomright: Score.inlet(process_object, 4)
        property var translation: Score.inlet(process_object, 5)
        property var scale: Score.inlet(process_object, 6)
    }

    // Denoise
    property QtObject denoise: QtObject {
        property var process_object: Score.find("Denoise")
        property var _c_identifier: Score.inlet(process_object, 0)
        property var noiseReduction: Score.inlet(process_object, 1)
        property var sharpness: Score.inlet(process_object, 2)
        property var kernelSize: Score.inlet(process_object, 3)
    }

    // Video Mapper 1
    property QtObject video_Mapper_1: QtObject {
        property var process_object: Score.find("Video Mapper.1")
        property var _c_identifier: Score.inlet(process_object, 0)
        property var topleft: Score.inlet(process_object, 1)
        property var bottomleft: Score.inlet(process_object, 2)
        property var topright: Score.inlet(process_object, 3)
        property var bottomright: Score.inlet(process_object, 4)
        property var translation: Score.inlet(process_object, 5)
        property var scale: Score.inlet(process_object, 6)
    }

    // GenAI Input Video
    property QtObject genai_inputvideo: QtObject {
        property var process_object: Score.find("genai_inputvideo")
    }
}
