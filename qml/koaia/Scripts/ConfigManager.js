.pragma library

var CONFIG_VERSION = "1.0";

function r(v) { return Math.round(v * 10000) / 10000; }

var WORKFLOW_TYPES = [
    "SD_TXT2IMG",
    "SD_IMG2IMG",
    "SD_TXT2IMG_CONTROLNET",
    "SD_TXT2IMG_IPADAPTER",
    "SD_IMG2IMG_IPADAPTER",
    "STURBO_TXT2IMG",
    "SDTURBO_IMG2IMG",
    "SDXL_TXT2IMG",
    "SDXL_IMG2IMG",
    "V2V_TXT2IMG",
    "V2V_IMG2IMG"
];

var GUIDANCE_TYPES   = ["None", "Self", "Full", "Initialize"];
var SHADER_TYPES     = ["Smoke", "Voronoi", "Noise", "Perlin"];
var SHAPE_TYPES      = ["Rectangle", "Triangle", "Circle", "Diamond"];
var RESOLUTION_TYPES = ["512 x 512", "1024 x 1024"];

// Default config structure

function createDefaultConfig() {
    return {
        version: CONFIG_VERSION,
        metadata: { timestamp: new Date().toISOString(), application: "Koaia" },
        input: {
            videoPath: "", videoAmount: 0.0, cameraAmount: 0.0
        },
        aiModel: {
            prompt: "origami, hyperrealistic, 4k, abstract, geometry",
            workflow: 0, enginePath: "", seed: 20, timesteps: "20",
            guidance: 1.0, guidanceType: 0, delta: 1.0,
            denoisingBatch: false, addNoise: false, manualMode: false, resolution: 0
        },
        noiseLayer: {
            noiseShader: 0, smokeAmount: 0.0, voronoiAmount: 0.0,
            noiseAmount: 0.0, perlinAmount: 0.0,
            voronoiSeed: 0.3, voronoiIregularity: 0.3, voronoiBlur: 0.3, voronoiScale: 0.4,
            whiteNoiseSeed: 0.3, perlinSeed: 0.3, perlinScale: 0.3
        },
        shapeLayer: {
            shapeType: 1, shapeAmount: 0.0, brightness: 0.1, hue: 0.0,
            shapeWidth: 0.5, shapeHeight: 0.5, shapeHRepeat: 1, shapeVRepeat: 1,
            shapeX: 256, shapeY: 256, invert: false
        }
    };
}

// Export 
// Takes the QML appSettings object (or any object with matching properties)
// and serialises the current state to a JSON string.

function exportConfig(s) {
    return JSON.stringify({
        version: CONFIG_VERSION,
        metadata: { timestamp: new Date().toISOString(), application: "Koaia" },
        input: {
            videoPath:    s.videoPath    || "",
            videoAmount:  r(s.videoAmount  || 0),
            cameraAmount: r(s.cameraAmount || 0)
        },
        aiModel: {
            prompt:         s.prompt        || "",
            workflow:       s.workflow      || 0,
            enginePath:     s.enginePath    || "",
            seed:           s.seed          !== undefined ? s.seed   : 20,
            timesteps:      s.timesteps     || "20",
            guidance:       r(s.guidance    !== undefined ? s.guidance : 1.0),
            guidanceType:   s.guidanceType  || 0,
            delta:          r(s.delta       !== undefined ? s.delta   : 1.0),
            denoisingBatch: s.denoisingBatch|| false,
            addNoise:       s.addNoise      || false,
            manualMode:     s.manualMode    || false,
            resolution:     s.resolution    || 0
        },
        noiseLayer: {
            noiseShader:        s.noiseShader        || 0,
            smokeAmount:        r(s.smokeAmount        || 0),
            voronoiAmount:      r(s.voronoiAmount      || 0),
            noiseAmount:        r(s.noiseAmount        || 0),
            perlinAmount:       r(s.perlinAmount       || 0),
            voronoiSeed:        r(s.voronoiSeed        !== undefined ? s.voronoiSeed        : 0.3),
            voronoiIregularity: r(s.voronoiIregularity !== undefined ? s.voronoiIregularity : 0.3),
            voronoiBlur:        r(s.voronoiBlur        !== undefined ? s.voronoiBlur        : 0.3),
            voronoiScale:       r(s.voronoiScale       !== undefined ? s.voronoiScale       : 0.4),
            whiteNoiseSeed:     r(s.whiteNoiseSeed     !== undefined ? s.whiteNoiseSeed     : 0.3),
            perlinSeed:         r(s.perlinSeed         !== undefined ? s.perlinSeed         : 0.3),
            perlinScale:        r(s.perlinScale        !== undefined ? s.perlinScale        : 0.3)
        },
        shapeLayer: {
            shapeType:    s.shapeType    || 0,
            shapeAmount:  r(s.shapeAmount  || 0),
            brightness:   r(s.shapeBrightness || 0.1),
            hue:          r(s.shapeHue     || 0),
            shapeWidth:   r(s.shapeWidth   !== undefined ? s.shapeWidth   : 0.5),
            shapeHeight:  r(s.shapeHeight  !== undefined ? s.shapeHeight  : 0.5),
            shapeHRepeat: r(s.shapeHRepeat !== undefined ? s.shapeHRepeat : 1),
            shapeVRepeat: r(s.shapeVRepeat !== undefined ? s.shapeVRepeat : 1),
            shapeX: s.shapeX !== undefined ? s.shapeX : 256,
            shapeY: s.shapeY !== undefined ? s.shapeY : 256,
            invert: s.shapeInvert || false
        }
    }, null, 2);
}

// Validation 

function validateConfig(config) {
    var result = { valid: true, errors: [] };

    if (!config) {
        result.valid = false;
        result.errors.push("Config is null or undefined");
        return result;
    }

    if (!config.version)    result.errors.push("Missing 'version' field");
    if (!config.input)      result.errors.push("Missing 'input' section");
    if (!config.aiModel)    result.errors.push("Missing 'aiModel' section");
    if (!config.noiseLayer) result.errors.push("Missing 'noiseLayer' section");
    if (!config.shapeLayer) result.errors.push("Missing 'shapeLayer' section");

    if (config.aiModel && config.aiModel.workflow !== undefined) {
        if (config.aiModel.workflow < 0 || config.aiModel.workflow >= WORKFLOW_TYPES.length)
            result.errors.push("Invalid workflow index: " + config.aiModel.workflow);
    }
    if (config.noiseLayer && config.noiseLayer.noiseShader !== undefined) {
        if (config.noiseLayer.noiseShader < 0 || config.noiseLayer.noiseShader >= SHADER_TYPES.length)
            result.errors.push("Invalid noiseShader index: " + config.noiseLayer.noiseShader);
    }
    if (config.shapeLayer && config.shapeLayer.shapeType !== undefined) {
        if (config.shapeLayer.shapeType < 0 || config.shapeLayer.shapeType >= SHAPE_TYPES.length)
            result.errors.push("Invalid shapeType index: " + config.shapeLayer.shapeType);
    }

    result.valid = result.errors.length === 0;
    return result;
}

// Apply
// Writes a parsed config object into a QML Settings object.
// mediaBasePath: resolved filesystem path to the bundled media/ dir (no trailing slash).
// Returns the resolved videoPath so the caller can handle {{media}} fallback display.

function applyConfig(config, settings, mediaBasePath) {
    var i = config.input
    if (i) {
        var rawPath = i.videoPath || ""
        if (rawPath.indexOf("{{media}}") !== -1) {
            rawPath = rawPath.replace("{{media}}", mediaBasePath)
        } else if (!rawPath) {
            rawPath = mediaBasePath + "/glow.mov"
        }
        settings.videoPath    = rawPath
        settings.videoAmount  = i.videoAmount  || 0
        settings.cameraAmount = i.cameraAmount || 0
    }
    var ai = config.aiModel
    if (ai) {
        settings.prompt         = ai.prompt        || ""
        settings.workflow       = ai.workflow       || 0
        settings.enginePath     = ai.enginePath     || ""
        settings.seed           = ai.seed           !== undefined ? ai.seed      : 20
        settings.timesteps      = ai.timesteps      || "20"
        settings.guidance       = ai.guidance       !== undefined ? ai.guidance  : 1.0
        settings.guidanceType   = ai.guidanceType   || 0
        settings.delta          = ai.delta          !== undefined ? ai.delta     : 1.0
        settings.denoisingBatch = ai.denoisingBatch || false
        settings.addNoise       = ai.addNoise       || false
        settings.manualMode     = ai.manualMode     || false
        settings.resolution     = ai.resolution     || 0
    }
    var n = config.noiseLayer
    if (n) {
        settings.noiseShader        = n.noiseShader        || 0
        settings.smokeAmount        = n.smokeAmount        || 0
        settings.voronoiAmount      = n.voronoiAmount      || 0
        settings.noiseAmount        = n.noiseAmount        || 0
        settings.perlinAmount       = n.perlinAmount       || 0
        settings.voronoiSeed        = n.voronoiSeed        !== undefined ? n.voronoiSeed        : 0.3
        settings.voronoiIregularity = n.voronoiIregularity !== undefined ? n.voronoiIregularity : 0.3
        settings.voronoiBlur        = n.voronoiBlur        !== undefined ? n.voronoiBlur        : 0.3
        settings.voronoiScale       = n.voronoiScale       !== undefined ? n.voronoiScale       : 0.4
        settings.whiteNoiseSeed     = n.whiteNoiseSeed     !== undefined ? n.whiteNoiseSeed     : 0.3
        settings.perlinSeed         = n.perlinSeed         !== undefined ? n.perlinSeed         : 0.3
        settings.perlinScale        = n.perlinScale        !== undefined ? n.perlinScale        : 0.3
    }
    var sh = config.shapeLayer
    if (sh) {
        settings.shapeType       = sh.shapeType    || 0
        settings.shapeAmount     = sh.shapeAmount  || 0
        settings.shapeBrightness = sh.brightness   || 0.1
        settings.shapeHue        = sh.hue          || 0
        settings.shapeWidth      = sh.shapeWidth   !== undefined ? sh.shapeWidth   : 0.5
        settings.shapeHeight     = sh.shapeHeight  !== undefined ? sh.shapeHeight  : 0.5
        settings.shapeHRepeat    = sh.shapeHRepeat !== undefined ? sh.shapeHRepeat : 1
        settings.shapeVRepeat    = sh.shapeVRepeat !== undefined ? sh.shapeVRepeat : 1
        settings.shapeX          = sh.shapeX       !== undefined ? sh.shapeX       : 256
        settings.shapeY          = sh.shapeY       !== undefined ? sh.shapeY       : 256
        settings.shapeInvert     = sh.invert        || false
    }
}

