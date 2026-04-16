.pragma library

var CONFIG_VERSION = "1.0";

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
            noiseAmount: 0.0, perlinAmount: 0.0
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
            videoAmount:  s.videoAmount  || 0,
            cameraAmount: s.cameraAmount || 0
        },
        aiModel: {
            prompt:         s.prompt        || "",
            workflow:       s.workflow      || 0,
            enginePath:     s.enginePath    || "",
            seed:           s.seed          !== undefined ? s.seed   : 20,
            timesteps:      s.timesteps     || "20",
            guidance:       s.guidance      !== undefined ? s.guidance : 1.0,
            guidanceType:   s.guidanceType  || 0,
            delta:          s.delta         !== undefined ? s.delta    : 1.0,
            denoisingBatch: s.denoisingBatch|| false,
            addNoise:       s.addNoise      || false,
            manualMode:     s.manualMode    || false,
            resolution:     s.resolution    || 0
        },
        noiseLayer: {
            noiseShader:   s.noiseShader   || 0,
            smokeAmount:   s.smokeAmount   || 0,
            voronoiAmount: s.voronoiAmount || 0,
            noiseAmount:   s.noiseAmount   || 0,
            perlinAmount:  s.perlinAmount  || 0
        },
        shapeLayer: {
            shapeType:    s.shapeType    || 0,
            shapeAmount:  s.shapeAmount  || 0,
            brightness:   s.shapeBrightness || 0.1,
            hue:          s.shapeHue     || 0,
            shapeWidth:   s.shapeWidth   !== undefined ? s.shapeWidth   : 0.5,
            shapeHeight:  s.shapeHeight  !== undefined ? s.shapeHeight  : 0.5,
            shapeHRepeat: s.shapeHRepeat !== undefined ? s.shapeHRepeat : 1,
            shapeVRepeat: s.shapeVRepeat !== undefined ? s.shapeVRepeat : 1,
            // shapeX/Y can legitimately be 0, so avoid the || fallback
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
    // Extract the timestamp we embedded so we can verify the write afterward.
    var expectedTimestamp;
    try { expectedTimestamp = JSON.parse(jsonString).metadata.timestamp; }
    catch (e) { expectedTimestamp = null; }

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;

        // Verify the write by reading back the file and confirming the timestamp.
        var verify = new XMLHttpRequest();
        verify.onreadystatechange = function() {
            if (verify.readyState !== XMLHttpRequest.DONE) return;
            if (verify.status === 200) {
                try {
                    var saved = JSON.parse(verify.responseText);
                    if (!expectedTimestamp || saved.metadata.timestamp === expectedTimestamp) {
                        console.log("[ConfigManager] Saved to:", fileUrl);
                        callback(true, null);
                        return;
                    }
                } catch (e) {}
            }
            console.error("[ConfigManager] Save verification failed for:", fileUrl);
            callback(false, "File write failed — ensure QML_XHR_ALLOW_FILE_WRITE=1 is set");
        };
        verify.open("GET", fileUrl);
        verify.send();
    };
    xhr.open("PUT", fileUrl);
    xhr.send(jsonString);
}

function loadConfigFromFile(fileUrl, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;
        if (xhr.status === 200) {
            console.log("[ConfigManager] Loaded from:", fileUrl);
            callback(true, xhr.responseText, null);
        } else {
            var err = xhr.status + (xhr.statusText ? " " + xhr.statusText : "");
            console.error("[ConfigManager] Load failed:", err);
            callback(false, null, err);
        }
    };
    xhr.open("GET", fileUrl);
    xhr.send();
}
