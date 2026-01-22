import QtQuick

QtObject {
    id: root

    // Image input
    property QtObject images_19: QtObject {
        property var process_object: Score.find("Images.19")
        property var images: Score.inlet(process_object, 5)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // Shape
    property QtObject shape: QtObject {
        property var process_object: Score.find("Basic Shape")
        property var maskShapeMode: Score.inlet(process_object, 1)
        property var shapeWidth: Score.inlet(process_object, 2)
        property var shapeHeight: Score.inlet(process_object, 3)
        property var center: Score.inlet(process_object, 4)
        property var invertMask: Score.inlet(process_object, 5)
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

    // Perlin Noise
    property QtObject perlin_Noise: QtObject {
        property var process_object: Score.find("Perlin Noise")
        property var seed: Score.inlet(process_object, 0)
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
        property var alpha7: Score.inlet(process_object, 14)
        property var alpha8: Score.inlet(process_object, 15)
        property var _c_identifier: Score.outlet(process_object, 0)
    }

    // StreamDiffusion
    property QtObject streamDiffusion_img2img: QtObject {
        property var process_object: Score.find("StreamDiffusion img2img")
        property var seed: Score.inlet(process_object, 6)
        property var steps: Score.inlet(process_object, 7)
        property var size: Score.inlet(process_object, 12)
    }

    // Prompt Composer
    property QtObject prompt_composer: QtObject {
        property var process_object: Score.find("Prompt composer")
        property var keywords: Score.inlet(process_object, 0)
    }

    // Video Mappers
    property QtObject video_Mapper: QtObject {
        property var process_object: Score.find("Video Mapper")
    }

    property QtObject video_Mapper_1: QtObject {
        property var process_object: Score.find("Video Mapper.1")
    }
}
