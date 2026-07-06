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

// File I/O 
//
// fileUrl must be a full file:// URL — pass selectedFile.toString() from FileDialog directly.
// Requires QML_XHR_ALLOW_FILE_READ=1 / QML_XHR_ALLOW_FILE_WRITE=1 in the environment.
//
// Note: Qt's XHR always returns status 0 for file:// PUT (no HTTP response code),
// even on success. We verify the write by reading the file back and checking that
// the timestamp in the saved content matches what we just wrote.

function saveConfigToFile(jsonString, fileUrl, callback) {
    try {
        var path = Utils.urlToLocalFile(fileUrl)
        Utils.writeFile(path, jsonString)
        console.log("[ConfigManager] Saved to:", path)
        callback(true, null)
    } catch(e) {
        console.error("[ConfigManager] Save failed:", e)
        callback(false, e.toString())
    }
}

function loadConfigFromFile(fileUrl, callback) {
    try {
        var path = Utils.urlToLocalFile(fileUrl)
        var content = Utils.readFile(path)
        if (!content) {
            callback(false, null, "File not found or empty: " + path)
            return
        }
        console.log("[ConfigManager] Loaded from:", path)
        callback(true, content, null)
    } catch(e) {
        console.error("[ConfigManager] Load failed:", e)
        callback(false, null, e.toString())
    }
}
