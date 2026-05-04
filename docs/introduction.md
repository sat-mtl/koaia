Koaia is a real-time generative AI GUI for creating visual effects. Combine camera feeds, video, shaders, and shape masks with AI models - all with live preview and parameter control.

<video src="images/koaia.mov" autoplay loop muted></video>

*video  Input (left) and AI-generated output (right).*

## Quick start

1. Ensure you have an NVIDIA GPU with CUDA (8GB VRAM for SD 1.5, 12GB for SDXL)
2. If you want to train your own models, ensure that you have at least 20 GB of free RAM
3. [Download](https://github.com/sat-mtl/koaia/releases) the build for your platform
4. Build a TensorRT engine from a Stable Diffusion model in the MODEL tab
5. Load the engine in the RUN tab and start generating

For more details, see [Installation](installation.md) and [Usage](usage.md).
