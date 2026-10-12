// Score device lifecycle for the input-source picker.
//
// InputSourceSelector is pure presentation; this is the half that talks to
// score. Ported from livepose's RunView.qml (_clearEnumerator / reenumerate /
// onDeviceAdded / onDeviceRemoved / _enumeratedSettings / _createInputDevice),
// with the sink changed from the pose detector's inlet to the video mixer's
// eighth texture inlet -- the one koaia's shader declares as t8 and whose Camera
// fader (alpha8) has been wired up and inert since the mixer was written.
//
// Not in qmlcomponents: the module ships the widget, not the lifecycle, and
// livepose and DomeportPro each have their own copy. A shared version is worth
// extracting once there are three working implementations to generalise from,
// not before.
.pragma library

var DEVICE_NAME = "Camera"
var MIXER_TEXTURE_INLET = 7          // video_mixer.fs "t8"; inlets 0..7 are the textures

// One live enumerator at a time, plus the label bookkeeping deviceRemoved needs
// (it only carries the name, while a camera's label also carries its category).
var _state = {
    enumerator: null,
    backend: "",
    labels: ({}),
    onAdded: null,
    onRemoved: null
}

// A camera enumerates one category per device and one name per mode, so the
// label needs both to stay unique.
function sourceLabel(backend, category, name) {
    return backend === "Camera" ? (category + ": " + name) : name
}

function clearEnumerator() {
    var e = _state.enumerator
    if (e) {
        try { e.deviceAdded.disconnect(_state.onAdded) } catch (err) {}
        try { e.deviceRemoved.disconnect(_state.onRemoved) } catch (err) {}
        try { e.enumerate = false } catch (err) {}
    }
    _state.enumerator = null
    _state.backend = ""
    _state.labels = ({})
    _state.onAdded = null
    _state.onRemoved = null
}

// Starts discovery for `backend` and calls onChange(labels) whenever the list
// moves. Discovery is always signal-driven, whatever the descriptor's
// `enumerate` says -- that field only picks the settings shape in createDevice.
function reenumerate(Score, descriptor, backend, onChange, log) {
    clearEnumerator()
    if (!descriptor || descriptor.kind !== "device") {
        onChange([])
        return
    }
    var labels = []
    _state.backend = backend
    _state.onAdded = function(factory, category, name) {
        var label = sourceLabel(backend, category, name)
        if (labels.indexOf(label) !== -1)
            return
        _state.labels[name] = label
        labels = labels.concat([label])
        onChange(labels)
    }
    _state.onRemoved = function(factory, name) {
        var label = _state.labels[name] || name
        delete _state.labels[name]
        var i = labels.indexOf(label)
        if (i === -1)
            return
        labels = labels.slice()
        labels.splice(i, 1)
        onChange(labels)
    }
    onChange(labels)
    try {
        _state.enumerator = Score.enumerateDevices(descriptor.uuid)
        _state.enumerator.deviceAdded.connect(_state.onAdded)
        _state.enumerator.deviceRemoved.connect(_state.onRemoved)
        _state.enumerator.enumerate = true
    } catch (e) {
        _state.enumerator = null
        if (log) log("Could not enumerate " + backend + ": " + e)
    }
}

// Read off the enumerator's own device list rather than caching the deviceAdded
// payload: the list is authoritative and survives a Refresh.
function _enumeratedSettings(label) {
    if (!_state.enumerator)
        return null
    var devs = _state.enumerator.devices
    for (var i = 0; i < devs.length; i++) {
        if (sourceLabel(_state.backend, devs[i].category, devs[i].name) === label)
            return devs[i].settings
    }
    return null
}

// Binds `label` to the mixer's t8 inlet. Call inside a Score macro.
// Returns true when the device was created and addressed.
function connectInMacro(Score, descriptor, label, mixerProcess, log) {
    if (!descriptor || descriptor.kind !== "device" || !mixerProcess)
        return false
    var settings = (descriptor.enumerate === "sync")
        ? _enumeratedSettings(label) : { "Path": label }
    if (!settings) {
        if (log) log("No enumerated settings for source: " + label)
        return false
    }
    try {
        Score.removeDevice(DEVICE_NAME)
        Score.createDevice(DEVICE_NAME, descriptor.uuid, settings)
        var inlet = Score.inlet(mixerProcess, MIXER_TEXTURE_INLET)
        if (!inlet) {
            if (log) log("The video mixer has no texture inlet " + MIXER_TEXTURE_INLET)
            return false
        }
        Score.setAddress(inlet, DEVICE_NAME + ":/")
        return true
    } catch (e) {
        if (log) log("Error creating input device: " + e)
        return false
    }
}

function disconnect(Score) {
    try { Score.removeDevice(DEVICE_NAME) } catch (e) {}
}
