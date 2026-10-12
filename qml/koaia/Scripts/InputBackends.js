// SPDX-License-Identifier: AGPL-3.0-or-later
// © Société des arts technologiques
//
// Single source of truth for the ossia/score video-input device backends.
// Pure data + helpers — NO Score.* calls here. The host app reads a
// descriptor's `uuid` and performs Score.createDevice/setAddress itself, so
// this library stays portable across apps.
//
// Device protocol UUIDs verified in ossia/score (score-plugin-gfx) and in the
// DomeportPro reference implementation:
//   Camera  d615690b-… (Gfx::CameraDevice)
//   NDI     ae78b7c6-… (NDI input addon)
//   Spout   3c995cb6-… (Gfx::Spout/SpoutInput)
//   Syphon  398cec01-… (Gfx::Syphon/SyphonInput)
.pragma library

const DESCRIPTORS = {
    "Camera": {
        kind: "device",
        uuid: "d615690b-f2e2-447b-b70e-a800552db69c",
        enumerate: "sync",      // read enumerator.devices once; reuse dev.settings
        typable: false,
        platforms: ["*"]
    },
    "NDI": {
        kind: "device",
        uuid: "ae78b7c6-6400-483e-b45b-fd6ff87ec700",
        enumerate: "async",     // discovered via deviceAdded/Removed; settings = {Path:name}
        typable: true,
        platforms: ["*"]
    },
    "Spout": {
        kind: "device",
        uuid: "3c995cb6-052b-4c52-a8fd-841b33b81b29",
        enumerate: "async",
        typable: true,
        platforms: ["windows"]
    },
    "Syphon": {
        kind: "device",
        uuid: "398cec01-c4ea-43b7-8281-d848748e0f68",
        enumerate: "sync",
        typable: true,
        platforms: ["osx"]
    },
    "Video file": {
        kind: "video"
    },
    "Image file": {
        kind: "image"
    }
}

function descriptor(name) {
    return DESCRIPTORS[name] || null
}

function isDevice(name) {
    const d = DESCRIPTORS[name]
    return !!d && d.kind === "device"
}

function isVideo(name) {
    const d = DESCRIPTORS[name]
    return !!d && d.kind === "video"
}

function isImage(name) {
    const d = DESCRIPTORS[name]
    return !!d && d.kind === "image"
}

function isTypable(name) {
    const d = DESCRIPTORS[name]
    return !!d && d.typable === true
}

// Platform-aware filter of an explicit backend allow-list. The host decides
// which protocols the selector may offer (e.g. ["Camera", "Video file", "Image file"] for a
// basic build, or ["Video file", "Image file", "NDI", "Spout", "Syphon"] for an advanced
// one); this keeps only the entries that exist and are valid on the current
// platform (Spout → Windows, Syphon → macOS). Unknown names are dropped.
// Order follows the host-provided list.
function filterBackends(names, platformOs) {
    const out = []
    if (!names)
        return out
    for (const name of names) {
        const d = DESCRIPTORS[name]
        if (!d)
            continue
        if (d.kind !== "device") {
            out.push(name)              // non-device entries (Video file, Image file) are always valid
            continue
        }
        if (d.platforms.indexOf("*") !== -1 || d.platforms.indexOf(platformOs) !== -1)
            out.push(name)
    }
    return out
}
