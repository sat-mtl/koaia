// Build presets: the train-lora.py invocations from librediffusion's README
// ("Engine build recipes (validated)"). One entry = one TensorRT bundle.
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

var presets = [
    // ---- SD 1.5 + ControlNet -------------------------------------------------
    // First and default: the 512x512 ControlNet pipeline koaia is built around.
    // sdxs needs its NATIVE sketch ControlNet -- the exported UNet/ControlNet pair
    // must agree on residual count (7 here), and a generic SD1.5 ControlNet (13)
    // will not bind.
    {
        slug: "sdxs-sketch", family: "SD 1.5 - ControlNet",
        label: "SDXS-sketch 512", type: "sd15",
        model: "IDKiro/sdxs-512-dreamshaper",
        controlnet: "IDKiro/sdxs-512-dreamshaper-sketch",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1,
        steps: "1", note: "koaia's default. Native sketch ControlNet."
    },
    {
        slug: "sdxs-sketch-portable", family: "SD 1.5 - ControlNet",
        label: "SDXS-sketch 512 (portable)", type: "sd15",
        model: "IDKiro/sdxs-512-dreamshaper",
        controlnet: "IDKiro/sdxs-512-dreamshaper-sketch",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1, hwCompat: "ampere_plus",
        steps: "1", note: "Runs on any Ampere-or-newer GPU, not just this one."
    },
    {
        slug: "lcm-dreamshaper-canny", family: "SD 1.5 - ControlNet",
        label: "LCM Dreamshaper + Canny", type: "sd15",
        model: "SimianLuo/LCM_Dreamshaper_v7",
        controlnet: "lllyasviel/control_v11p_sd15_canny",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "lcm-dreamshaper-depth", family: "SD 1.5 - ControlNet",
        label: "LCM Dreamshaper + Depth", type: "sd15",
        model: "SimianLuo/LCM_Dreamshaper_v7",
        controlnet: "lllyasviel/control_v11f1p_sd15_depth",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "lcm-dreamshaper-openpose", family: "SD 1.5 - ControlNet",
        label: "LCM Dreamshaper + OpenPose", type: "sd15",
        model: "SimianLuo/LCM_Dreamshaper_v7",
        controlnet: "lllyasviel/control_v11p_sd15_openpose",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "lcm-dreamshaper-softedge", family: "SD 1.5 - ControlNet",
        label: "LCM Dreamshaper + SoftEdge", type: "sd15",
        model: "SimianLuo/LCM_Dreamshaper_v7",
        controlnet: "lllyasviel/control_v11p_sd15_softedge",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },

    // ---- SD 1.5 base ---------------------------------------------------------
    {
        slug: "sd-turbo", family: "SD 1.5",
        label: "SD-Turbo 512", type: "sd15",
        model: "stabilityai/sd-turbo",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "sd-turbo-768", family: "SD 1.5",
        label: "SD-Turbo 768", type: "sd15",
        model: "stabilityai/sd-turbo",
        minRes: 768, maxRes: 768, optWidth: 768, optHeight: 768,
        minBatch: 1, optBatch: 1, maxBatch: 1, steps: "1"
    },
    {
        slug: "sd-turbo-512x768", family: "SD 1.5",
        label: "SD-Turbo 512x768", type: "sd15",
        model: "stabilityai/sd-turbo",
        minRes: 512, maxRes: 768, optWidth: 512, optHeight: 768,
        minWidth: 512, maxWidth: 512, minHeight: 768, maxHeight: 768,
        minBatch: 1, optBatch: 1, maxBatch: 1,
        steps: "1", note: "Portrait geometry is baked per-axis, not a runtime knob."
    },
    {
        slug: "sd-turbo-768x512", family: "SD 1.5",
        label: "SD-Turbo 768x512", type: "sd15",
        model: "stabilityai/sd-turbo",
        minRes: 512, maxRes: 768, optWidth: 768, optHeight: 512,
        minWidth: 768, maxWidth: 768, minHeight: 512, maxHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1,
        steps: "1", note: "Landscape counterpart of the above; a separate engine."
    },
    {
        slug: "sdxs", family: "SD 1.5",
        label: "SDXS 512", type: "sd15",
        model: "IDKiro/sdxs-512-dreamshaper",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1, steps: "1"
    },
    {
        slug: "lcm-dreamshaper", family: "SD 1.5",
        label: "LCM Dreamshaper v7", type: "sd15",
        model: "SimianLuo/LCM_Dreamshaper_v7",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "lcm-dreamshaper-4step", family: "SD 1.5",
        label: "LCM Dreamshaper v7 (4 steps)", type: "sd15",
        model: "SimianLuo/LCM_Dreamshaper_v7",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 4, maxBatch: 4,
        steps: "1-4", note: "Same weights as above, batch 4 so 4 steps fit."
    },
    {
        slug: "dreamshaper-8-lcm", family: "SD 1.5",
        label: "Dreamshaper 8 LCM", type: "sd15",
        model: "Lykon/dreamshaper-8-lcm",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "sd15-lcm-lora", family: "SD 1.5",
        label: "SD 1.5 + LCM-LoRA", type: "sd15",
        model: "runwayml/stable-diffusion-v1-5",
        loras: [{ path: "latent-consistency/lcm-lora-sdv1-5" }],
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "hyper-sd15-1step", family: "SD 1.5",
        label: "SD 1.5 Hyper-SD 1-step", type: "sd15",
        model: "runwayml/stable-diffusion-v1-5",
        loras: [{ path: "ByteDance/Hyper-SD|Hyper-SD15-1step-lora.safetensors" }],
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1, steps: "1"
    },
    {
        slug: "hyper-sd15-2step", family: "SD 1.5",
        label: "SD 1.5 Hyper-SD 2-step", type: "sd15",
        model: "runwayml/stable-diffusion-v1-5",
        loras: [{ path: "ByteDance/Hyper-SD|Hyper-SD15-2steps-lora.safetensors" }],
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "2"
    },
    {
        slug: "hyper-sd15", family: "SD 1.5",
        label: "SD 1.5 Hyper-SD 4-step", type: "sd15",
        model: "runwayml/stable-diffusion-v1-5",
        loras: [{ path: "ByteDance/Hyper-SD|Hyper-SD15-4steps-lora.safetensors" }],
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 4, steps: "4"
    },
    {
        slug: "sd21-base-1step", family: "SD 1.5",
        label: "SD 2.1 base 1-step", type: "sd15",
        model: "sd-research/stable-diffusion-2-1-base",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1,
        steps: "1", note: "SD 2.1 exports through the sd15 path (1024-dim CLIP)."
    },
    {
        slug: "sd21-base-4step", family: "SD 1.5",
        label: "SD 2.1 base 4-step", type: "sd15",
        model: "sd-research/stable-diffusion-2-1-base",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 4, steps: "4"
    },

    // ---- SD 1.5 IP-Adapter ---------------------------------------------------
    // --ipadapter also exports clip_image_encoder.engine + ip_image_proj.engine,
    // without which the node silently ignores the Control/Style texture.
    {
        slug: "lcm-dreamshaper-ip", family: "SD 1.5 - IP-Adapter",
        label: "LCM Dreamshaper + IP-Adapter", type: "sd15",
        model: "SimianLuo/LCM_Dreamshaper_v7",
        ipadapterNeeded: true, ipadapterHint: "h94/IP-Adapter models/ip-adapter_sd15.bin",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2",
        requires: "a local ip-adapter_sd15.bin: train-lora.py loads the checkpoint "
                + "from disk, so fill in the IP-Adapter field before building",
        note: "Not available for sdxs: its attention differs."
    },

    // ---- SDXL ----------------------------------------------------------------
    {
        slug: "sdxl-turbo", family: "SDXL",
        label: "SDXL-Turbo 1024", type: "sdxl",
        model: "stabilityai/sdxl-turbo",
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "sdxl-turbo-512", family: "SDXL",
        label: "SDXL-Turbo 512", type: "sdxl",
        model: "stabilityai/sdxl-turbo",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1, steps: "1"
    },
    {
        slug: "sdxl-base", family: "SDXL",
        label: "SDXL base 1.0", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 2,
        steps: "many", note: "Undistilled: needs many steps. Prefer a turbo/LCM variant."
    },
    {
        slug: "sdxl-lcm-lora", family: "SDXL",
        label: "SDXL + LCM-LoRA", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        loras: [{ path: "latent-consistency/lcm-lora-sdxl" }],
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 4, steps: "2-4"
    },
    {
        slug: "hyper-sdxl", family: "SDXL",
        label: "SDXL Hyper-SD 4-step", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        loras: [{ path: "ByteDance/Hyper-SD|Hyper-SDXL-4steps-lora.safetensors" }],
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 4, steps: "4"
    },
    {
        slug: "sdxl-lightning", family: "SDXL",
        label: "SDXL Lightning 4-step", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        loras: [{ path: "ByteDance/SDXL-Lightning|sdxl_lightning_4step_lora.safetensors" }],
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 4, steps: "4"
    },
    {
        slug: "vega-rt", family: "SDXL",
        label: "Segmind VegaRT", type: "sdxl",
        model: "segmind/Segmind-Vega",
        loras: [{ path: "segmind/Segmind-VegaRT" }],
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "2"
    },
    {
        slug: "sdxl-lcm-crayon", family: "SDXL",
        label: "SDXL LCM + crayon style", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        loras: [
            { path: "latent-consistency/lcm-lora-sdxl" },
            { path: "ostris/crayon_style_lora_sdxl|crayons_v1_sdxl.safetensors" }
        ],
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 4,
        steps: "2-4", note: "Stacked LoRAs, both fused at export."
    },
    {
        slug: "crayon-rt", family: "SDXL",
        label: "SDXL + crayon (runtime LoRA)", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        loras: [{ path: "ostris/crayon_style_lora_sdxl|crayons_v1_sdxl.safetensors", runtime: true }],
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 2,
        steps: "2", note: "Unfused: the node's LoRA-scale knob drives it live. Costs ~2%."
    },

    // ---- SDXL with a replacement UNet ---------------------------------------
    // --unet swaps the UNet weights only; the rest of the pipeline stays SDXL
    // base. DMD2 is CC-BY-NC-4.0.
    {
        slug: "dmd2-sdxl-1step", family: "SDXL - distilled UNet",
        label: "SDXL DMD2 1-step", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        unet: "tianweiy/DMD2|dmd2_sdxl_1step_unet_fp16.bin",
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 1, maxBatch: 1,
        steps: "1", note: "txt2img only. CC-BY-NC-4.0."
    },
    {
        slug: "dmd2-sdxl-4step", family: "SDXL - distilled UNet",
        label: "SDXL DMD2 4-step", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        unet: "tianweiy/DMD2|dmd2_sdxl_4step_unet_fp16.bin",
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 4, maxBatch: 4,
        steps: "1-4", note: "CC-BY-NC-4.0."
    },
    {
        slug: "nitrosd-realism", family: "SDXL - distilled UNet",
        label: "SDXL NitroSD Realism", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        unet: "ChenDY/NitroFusion|nitrosd-realism_unet.safetensors",
        unetTimestepScale: 0.25,
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },
    {
        slug: "nitrosd-vibrant", family: "SDXL - distilled UNet",
        label: "SDXL NitroSD Vibrant", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        unet: "ChenDY/NitroFusion|nitrosd-vibrant_unet.safetensors",
        unetTimestepScale: 0.5,
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2"
    },

    // ---- SDXL ControlNet -----------------------------------------------------
    {
        slug: "sdxl-lcm-lora-canny", family: "SDXL - ControlNet",
        label: "SDXL LCM + Canny", type: "sdxl",
        model: "stabilityai/stable-diffusion-xl-base-1.0",
        loras: [{ path: "latent-consistency/lcm-lora-sdxl" }],
        controlnet: "diffusers/controlnet-canny-sdxl-1.0",
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 4, steps: "2-4"
    },
    {
        slug: "sdxl-turbo-ip", family: "SDXL - IP-Adapter",
        label: "SDXL-Turbo + IP-Adapter", type: "sdxl",
        model: "stabilityai/sdxl-turbo",
        ipadapterNeeded: true, ipadapterHint: "h94/IP-Adapter sdxl_models/ip-adapter_sdxl_vit-h.bin",
        minRes: 1024, maxRes: 1024, optWidth: 1024, optHeight: 1024,
        minBatch: 1, optBatch: 2, maxBatch: 2, steps: "1-2",
        requires: "a local ip-adapter_sdxl_vit-h.bin: train-lora.py loads the checkpoint "
                + "from disk, so fill in the IP-Adapter field before building"
    },

    // ---- img2img-turbo -------------------------------------------------------
    // A separate C++ node path: a skip-VAE pix2pix-turbo pipeline, not SD.
    {
        slug: "img2img-turbo", family: "img2img-turbo",
        label: "img2img-turbo edge2image", type: "img2img-turbo",
        model: "edge_to_image",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1, steps: "1"
    },
    {
        slug: "img2img-turbo-sketch", family: "img2img-turbo",
        label: "img2img-turbo sketch2image", type: "img2img-turbo",
        model: "sketch_to_image_stochastic",
        minRes: 512, maxRes: 512, optWidth: 512, optHeight: 512,
        minBatch: 1, optBatch: 1, maxBatch: 1, steps: "1"
    },

    // ---- FLUX.2-klein -------------------------------------------------------
    // train-lora.py does NOT download klein: it looks the snapshot up in the HF
    // cache and exits if it is absent. Native geometry is 320x576 unless an
    // explicit --opt-width/--opt-height is passed. RIFE always ships.
    {
        slug: "klein", family: "FLUX.2-klein",
        label: "FLUX.2-klein 320x576", type: "klein",
        model: "black-forest-labs/FLUX.2-klein-4B",
        minRes: 320, maxRes: 576, optWidth: 320, optHeight: 576,
        minBatch: 1, optBatch: 1, maxBatch: 1, kleinQuality: "both",
        steps: "2",
        requires: "the FLUX.2-klein-4B snapshot in the model cache "
                + "(hf download black-forest-labs/FLUX.2-klein-4B --exclude flux-2-klein-4b.safetensors)",
        note: "~18 GB bundle. 'both' builds the bf16 and fp8 pair; fp8 needs SM 8.9+."
    },
    {
        slug: "klein-landscape", family: "FLUX.2-klein",
        label: "FLUX.2-klein 576x320", type: "klein",
        model: "black-forest-labs/FLUX.2-klein-4B",
        minRes: 320, maxRes: 576, optWidth: 576, optHeight: 320,
        minBatch: 1, optBatch: 1, maxBatch: 1, kleinQuality: "both",
        steps: "2",
        requires: "the FLUX.2-klein-4B snapshot in the model cache",
        note: "Landscape needs its own VAE pair, so it is a separate bundle."
    },
    {
        slug: "klein-sprint", family: "FLUX.2-klein",
        label: "FLUX.2-klein Sana-Sprint", type: "klein",
        model: "black-forest-labs/FLUX.2-klein-4B",
        loras: [{ path: "radames/FLUX.2-klein-Sana-Sprint" }],
        minRes: 320, maxRes: 576, optWidth: 320, optHeight: 576,
        minBatch: 1, optBatch: 1, maxBatch: 1, kleinQuality: "both",
        // --lora is accepted by every builder, but a builder without the klein
        // fusion path ignores it and emits a plain klein bundle under this name.
        needsBuilderSymbol: "klein_fuse_loras",
        needsBuilderLabel: "LoRA fusion for klein",
        steps: "1-2",
        requires: "the FLUX.2-klein-4B snapshot in the model cache",
        note: "The LoRA is fused into a transformer-only copy first."
    }
]

// Menu order; anything not listed is appended after.
var familyOrder = [
    "SD 1.5 - ControlNet", "SD 1.5", "SD 1.5 - IP-Adapter",
    "SDXL", "SDXL - distilled UNet", "SDXL - ControlNet", "SDXL - IP-Adapter",
    "img2img-turbo", "FLUX.2-klein"
]

function byFamily() {
    var grp = ({}), order = []
    for (var i = 0; i < presets.length; i++) {
        var f = presets[i].family
        if (!grp[f]) { grp[f] = []; order.push(f) }
        grp[f].push(presets[i])
    }
    order.sort(function(a, b) {
        var ia = familyOrder.indexOf(a); if (ia < 0) ia = 999
        var ib = familyOrder.indexOf(b); if (ib < 0) ib = 999
        return ia - ib
    })
    return { groups: grp, order: order }
}

function find(slug) {
    for (var i = 0; i < presets.length; i++)
        if (presets[i].slug === slug) return presets[i]
    return null
}

function loraArg(l) {
    if (l.runtime) return l.path + ":runtime"
    if (l.weight !== undefined && l.weight !== 1.0) return l.path + ":" + l.weight.toFixed(2)
    return l.path
}

// The flags that have no widget of their own in ModelView. Everything here is
// carried by the preset alone, so a preset is the only way to reach --unet,
// --ipadapter, --hw-compat, --klein-quality, the per-axis geometry flags and a
// :runtime LoRA.
function extraArgs(p) {
    var a = []
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
    var a = extraArgs(p)
    var loras = (p.loras || []).map(loraArg)
    var parts = []
    for (var i = 0; i < a.length; i += 2) parts.push(a[i] + " " + a[i + 1])
    for (var j = 0; j < loras.length; j++) parts.push("--lora " + loras[j])
    return parts.join("  ")
}
