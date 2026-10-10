.pragma library

// Builds koaia's render graph at runtime through the Score JS API. The ISF
// sources are read from score/shaders/*.fs (+ .vs).

var ISF      = "74ca45ff-92c9-44a0-8f1a-754dea05ee1b"  // Gfx::Filter (ISF Shader)
var VIDEO    = "32dc5341-7748-4c31-a226-82e6bd685744"  // Gfx::Video
var SDIFF    = "a202d577-f92e-4d47-b863-62be5c02084e"  // StreamDiffusion
var COMPOSER = "a4227e94-cf7d-4776-9aa0-2f384be7d97f"  // Prompt composer

// 0.457 is 54.84/120: the pair plays glow.mov at its native rate. Keep both.
var INTERVAL_SPEED = 0.457
var VIDEO_TEMPO = 54.84
var VIDEO_SCALE_STRETCH = 3                            // score::gfx::ScaleMode
var VIDEO_TONEMAP_AUTO = 8                             // Video::Tonemap

// Values no UI control and no config key drives.
var BAKED = {
    denoise:       [[1, 0.5718470811843872], [2, 44.59842300415039], [3, 8]],
    simplex_Noise: [[1, 0.30000001192092896]],
    // The composer emits "(<keywords>:<weight>)": the weight is prompt text.
    prompt_composer: [[2, 0.5924424529075623]]
}

function _preset(name, frag, vert) {
    return JSON.stringify({
        Key: { Uuid: ISF, Effect: "" },
        Name: name,
        Preset: { Fragment: frag, Vertex: vert || "", Controls: [] }
    })
}

// score/ sits next to qml/ in a package, under score/ in the source tree.
function shaderDir(Util, qmlDir) {
    var candidates = [qmlDir + "/../../../shaders", qmlDir + "/../../../score/shaders"]
    for (var i = 0; i < candidates.length; i++)
        if (Util.fileExists(candidates[i] + "/video_mapper.vs"))
            return candidates[i]
    return null
}

// loadPreset rebuilds the inlets from the shader, so create, preset, then name.
function _isf(Score, Util, dir, name, file) {
    var frag = String(Util.readFile(dir + "/" + file + ".fs"))
    if (!frag) throw new Error("missing shader " + file + ".fs")
    var vertPath = dir + "/" + file + ".vs"
    var vert = Util.fileExists(vertPath) ? String(Util.readFile(vertPath)) : ""
    var p = Score.createProcess(Score.rootInterval(), ISF, "")
    if (!p) throw new Error("could not create ISF process " + name)
    Score.loadPreset(p, _preset(name, frag, vert))
    Score.setName(p, name)
    return p
}

function build(Score, Util, qmlDir, log) {
    var dir = shaderDir(Util, qmlDir)
    if (!dir) {
        log("[ScoreGraph] no shader directory found next to " + qmlDir)
        return null
    }

    var out = null
    Score.withMacro(function() {
        var root = Score.rootInterval()

        var p = {
            shape:          _isf(Score, Util, dir, "Basic Shape",    "basic_shape"),
            smoke:          _isf(Score, Util, dir, "Smoke",          "smoke"),
            voronoi:        _isf(Score, Util, dir, "Voronoi",        "voronoi"),
            perlin_Noise:   _isf(Score, Util, dir, "Perlin Noise",   "perlin_noise"),
            simplex_Noise:  _isf(Score, Util, dir, "Simplex Noise",  "simplex_noise"),
            white_Noise:    _isf(Score, Util, dir, "White Noise",    "white_noise"),
            video_Mixer:    _isf(Score, Util, dir, "Video Mixer",    "video_mixer"),
            video_Mapper:   _isf(Score, Util, dir, "Video Mapper",   "video_mapper"),
            denoise:        _isf(Score, Util, dir, "Denoise",        "denoise"),
            video_Mapper_1: _isf(Score, Util, dir, "Video Mapper.1", "video_mapper")
        }

        p.genai_inputvideo = Score.createProcess(root, VIDEO, "")
        p.streamDiffusion  = Score.createProcess(root, SDIFF, "")
        p.prompt_composer  = Score.createProcess(root, COMPOSER, "")
        if (!p.genai_inputvideo || !p.streamDiffusion || !p.prompt_composer)
            throw new Error("could not create the video / diffusion / composer processes")

        Score.setName(p.genai_inputvideo, "genai_inputvideo")
        Score.setName(p.streamDiffusion, "StreamDiffusion")
        Score.setName(p.prompt_composer, "Prompt composer")

        p.genai_inputvideo.scaleMode = VIDEO_SCALE_STRETCH
        p.genai_inputvideo.tonemap = VIDEO_TONEMAP_AUTO
        p.genai_inputvideo.nativeTempo = VIDEO_TEMPO

        // Layers into the mixer, in the inlet order video_mixer.fs declares.
        var layers = [p.shape, p.smoke, p.voronoi, p.perlin_Noise,
                      p.simplex_Noise, p.white_Noise, p.genai_inputvideo]
        for (var i = 0; i < layers.length; i++)
            _cable(Score, layers[i], 0, p.video_Mixer, i, log)

        _cable(Score, p.video_Mixer, 0, p.video_Mapper, 0, log)
        _cable(Score, p.video_Mapper, 0, p.streamDiffusion, "In", log)
        _cable(Score, p.prompt_composer, 0, p.streamDiffusion, "Prompt +", log)
        _cable(Score, p.streamDiffusion, 0, p.denoise, 0, log)
        _cable(Score, p.denoise, 0, p.video_Mapper_1, 0, log)

        for (var key in BAKED) {
            var vals = BAKED[key]
            for (var j = 0; j < vals.length; j++) {
                var port = Score.inlet(p[key], vals[j][0])
                if (port) Score.setValue(port, vals[j][1])
                else log("[ScoreGraph] " + key + " has no inlet " + vals[j][0])
            }
        }

        Score.setIntervalSpeed(root, INTERVAL_SPEED)
        out = p
    })
    return out
}

function _cable(Score, src, srcPort, sink, sinkPort, log) {
    var o = Score.outlet(src, srcPort)
    var i = Score.inlet(sink, sinkPort)
    if (!o || !i) {
        log("[ScoreGraph] unresolved cable: out=" + o + " in=" + i
            + " (" + srcPort + " -> " + sinkPort + ")")
        return
    }
    Score.createCable(o, i)
}
