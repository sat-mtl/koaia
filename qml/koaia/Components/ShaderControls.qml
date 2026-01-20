import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Score.UI as UI
import koaia

ColumnLayout {
    property var voronoi: null
    property var perlin_Noise: null
    property var video_Mixer: null
    property int shaderType: 0 // 0=Smoke, 1=Voronoi, 2=Noise, 3=Perlin

    spacing: appStyle.spacing

    // Voronoi controls
    ParameterSlider {
        visible: shaderType === 1
        labelText: "Seed"
        port: voronoi ? voronoi.seed : null
        from: 0
        to: 100
        initialValue: 0.3
    }

    ParameterSlider {
        visible: shaderType === 1
        labelText: "Iregularity"
        port: voronoi ? voronoi.iregularity : null
        from: 0
        to: 1
        initialValue: 0.3
    }

    ParameterSlider {
        visible: shaderType === 1
        labelText: "Blur"
        port: voronoi ? voronoi.blur : null
        from: 0
        to: 1
        initialValue: 0.3
    }

    ParameterSlider {
        visible: shaderType === 1
        labelText: "Scale"
        port: voronoi ? voronoi.scale : null
        from: 0
        to: 100
        initialValue: 0.4
    }

    // Perlin controls
    ParameterSlider {
        visible: shaderType === 3
        labelText: "Seed"
        port: perlin_Noise ? perlin_Noise.seed : null
        from: 0
        to: 100
        initialValue: 0.3
    }

    ParameterSlider {
        visible: shaderType === 3
        labelText: "Scale"
        port: perlin_Noise ? perlin_Noise.scale : null
        from: 0
        to: 100
        initialValue: 0.3
    }
}
