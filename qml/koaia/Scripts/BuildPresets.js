// Build presets: the train-lora.py invocations from librediffusion's README
// ("Engine build recipes (validated)"). One entry = one TensorRT bundle.
//
// The recipes are data and live in ../BuildPresets/NNN-<slug>.json, one file per
// bundle, shipped with the app; this file is only the logic that turns one of
// them into train-lora.py flags. Adding a recipe means dropping in a file.
//
// The NNN prefix is the catalogue order and it matters twice: the first file is
// the preset the builder starts on, and BuildPresetView's sections follow the
// order in which families first appear. A "comment" field is read by nobody: it
// is where a recipe's rationale lives, since JSON carries no comments.
//
// A build preset is not a runtime preset. This produces the engines; the
// StreamDiffusion node's own .scp presets then configure a bundle that already
// exists. The two meet only at `slug`, which is the bundle folder name, so
// renaming one breaks the runtime side's ability to find its engines.
//
// Batch, geometry and the controlnet/ipadapter/unet choice are BAKED into the
// engine: a runtime preset that wants 4 denoising steps needs maxBatch >= 4 at
// build time, and a 512x768 preset needs a bundle built for 512x768. That is why
// near-duplicate entries like hyper-sd15-{1,2,4}step exist.
.pragma library

var presets = []
var _loaded = false

// Fields without which a card cannot be drawn or a build started. Everything
// else is optional, and absence is meaningful: see extraArgs.
var _REQUIRED_TEXT = ["slug", "family", "label", "type", "model"]
var _REQUIRED_NUMBERS = ["minRes", "maxRes", "optWidth", "optHeight",
                         "minBatch", "optBatch", "maxBatch"]

// The catalogue, read once per engine. Score's Util has to be handed in: a
// .pragma library sees no QML context, and XMLHttpRequest is no way out either,
// since it cannot list a directory and Qt refuses GET on a local file unless
// QML_XHR_ALLOW_FILE_READ is set.
function all(Util) {
    if (!_loaded)
        _load(Util)
    return presets
}

function _load(Util) {
    _loaded = true
    if (!Util || !Util.listFiles) {
        console.warn("[BuildPresets] no Util.listFiles: the catalogue cannot be read")
        return
    }
    var dir = Util.urlToLocalFile("" + Qt.resolvedUrl("../BuildPresets"))
    var files = Util.listFiles(dir, "*.json")
    // Sorted here rather than taken on trust from listFiles: the NNN prefix is
    // the catalogue order, and order is load-bearing.
    files.sort()
    for (var i = 0; i < files.length; i++) {
        var p = _parse(Util, files[i])
        if (p)
            presets.push(p)
    }
    if (presets.length === 0)
        console.warn("[BuildPresets] no usable preset in " + dir)
}

// A recipe is a file now, so a broken one costs its own card and nothing else.
function _parse(Util, path) {
    try {
        var p = JSON.parse(String(Util.readFile(path)))
        for (var i = 0; i < _REQUIRED_TEXT.length; i++)
            if (!p[_REQUIRED_TEXT[i]] || typeof p[_REQUIRED_TEXT[i]] !== "string")
                throw new Error("no " + _REQUIRED_TEXT[i])
        for (var j = 0; j < _REQUIRED_NUMBERS.length; j++)
            if (typeof p[_REQUIRED_NUMBERS[j]] !== "number")
                throw new Error("no " + _REQUIRED_NUMBERS[j])
        return p
    } catch (e) {
        console.warn("[BuildPresets] skipping " + path + ": " + e)
        return null
    }
}

// Cards grouped into sections, families in the order they first appear.
function byFamily(list) {
    var grp = ({}), order = []
    for (var i = 0; i < list.length; i++) {
        var f = list[i].family
        if (!grp[f]) { grp[f] = []; order.push(f) }
        grp[f].push(list[i])
    }
    return { groups: grp, order: order }
}

function find(list, slug) {
    for (var i = 0; i < list.length; i++)
        if (list[i].slug === slug) return list[i]
    return null
}

function loraArg(l) {
    if (l.runtime) return l.path + ":runtime"
    if (l.weight !== undefined && l.weight !== 1.0) return l.path + ":" + l.weight.toFixed(2)
    return l.path
}

// The flags that have no widget of their own in ModelView. Everything here is
// carried by the preset alone, so a preset is the only way to reach --unet
// (which swaps the UNet weights only, leaving the rest of the pipeline alone),
// --ipadapter, --hw-compat, --klein-quality, the per-axis geometry flags and a
// :runtime LoRA.
function extraArgs(p) {
    var a = []
    if (!p) return a
    if (p.unet) a.push("--unet", p.unet)
    if (p.unetTimestepScale !== undefined)
        a.push("--unet-timestep-scale", p.unetTimestepScale.toString())
    if (p.hwCompat) a.push("--hw-compat", p.hwCompat)
    if (p.kleinQuality) a.push("--klein-quality", p.kleinQuality)
    // Per-axis bounds override the square --min/--max-resolution in train-lora.py,
    // so passing both is safe and only the non-square presets need these.
    if (p.minWidth !== undefined) a.push("--min-width", p.minWidth.toString())
    if (p.maxWidth !== undefined) a.push("--max-width", p.maxWidth.toString())
    if (p.minHeight !== undefined) a.push("--min-height", p.minHeight.toString())
    if (p.maxHeight !== undefined) a.push("--max-height", p.maxHeight.toString())
    return a
}

// The flag names a preset needs beyond the ones every build passes. The staged
// train-lora.py comes from koaia's 3rdparty/librediffusion pin, which can be
// older than the recipes here, so the builder checks these before running.
function requiredFlags(p) {
    var a = extraArgs(p), out = []
    for (var i = 0; i < a.length; i += 2)
        out.push(a[i])
    return out
}

// One-line human summary of extraArgs, for the builder to show what a preset
// adds beyond the visible fields.
function extraSummary(p) {
    if (!p) return ""
    var a = extraArgs(p)
    var loras = (p.loras || []).map(loraArg)
    var parts = []
    for (var i = 0; i < a.length; i += 2) parts.push(a[i] + " " + a[i + 1])
    for (var j = 0; j < loras.length; j++) parts.push("--lora " + loras[j])
    return parts.join("  ")
}
