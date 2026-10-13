#!/usr/bin/env bash
# Stage the GPU runtime koaia needs — librediffusion plus CUDA 13, cuDNN 9 and
# TensorRT 11 — into an already-packaged Linux Koaia AppImage, and repack it.
#
# This is the Linux half of bundle-gpu-windows.sh, and it exists for the same
# reason: score-addon-librediffusion never links librediffusion, it dlopen()s it
# at run time, so the packaged app-bin imports none of this and create-app-linux
# has nothing to copy. A package built without this step starts, shows the UI,
# and cannot reach the GPU at all. Read that script's header for why an import
# walk is not sufficient and why the builder resources are not optional — both
# apply here unchanged.
#
# TWO THINGS ARE LINUX-SPECIFIC.
#
# 1. The libraries go into usr/lib, which AppRun already places on
#    LD_LIBRARY_PATH, so no launcher change is needed.
#
# 2. The seven libs from the `libxcb` PACKAGE are removed if present. They are
#    protocol bindings generated from xcb-proto and have to track the X server
#    they talk to; a bundled copy older than the host's server segfaults the app
#    during plugin init, before any window appears. Current packaging ships only
#    the six xcb-util-* helpers and none of these, so this is a guard against
#    that regression rather than a live fix — expect it to remove nothing.
#    The helpers are kept deliberately: distributions do not all ship them
#    (Ubuntu has no xcb-util-cursor, which Qt 6.5+ requires).
#
# The runtime source must be the version-matched bundle, NOT the host's
# /opt/cuda: koaia's engines are built against this exact CUDA/cuDNN/TensorRT
# matrix and a mismatched cuDNN loads but then fails at engine deserialisation.
#
# Usage: bundle-gpu-linux.sh <package.AppImage|AppDir> [runtime-dir]
# The runtime source defaults to $KOAIA_GPU_RUNTIME. appimagetool is taken from
# $APPIMAGETOOL when set.

set -euo pipefail

TARGET="${1:-}"
RUNTIME="${2:-${KOAIA_GPU_RUNTIME:-}}"

if [[ -z "$TARGET" || -z "$RUNTIME" ]]; then
  echo "usage: $0 <package.AppImage|AppDir> [runtime-dir]" >&2
  echo "       the runtime source may also come from \$KOAIA_GPU_RUNTIME" >&2
  exit 2
fi

# Protocol bindings that must match the host X server, so they cannot be bundled.
LIBXCB_PKG="libxcb-randr.so.0 libxcb-render.so.0 libxcb-shape.so.0 libxcb-shm.so.0
            libxcb-sync.so.1 libxcb-xfixes.so.0 libxcb-xinput.so.0"
# curand/nvrtc/nvJitLink serve onnxruntime's CUDA provider too, not only TensorRT.
CUDA_CORE="libcublas.so.13 libcublasLt.so.13 libcudart.so.13 libcufft.so.12
           libcurand.so.10 libnvrtc.so.13 libnvJitLink.so.13"
CUDNN="libcudnn.so.9 libcudnn_adv.so.9 libcudnn_cnn.so.9
       libcudnn_engines_precompiled.so.9 libcudnn_engines_runtime_compiled.so.9
       libcudnn_graph.so.9 libcudnn_heuristic.so.9 libcudnn_ops.so.9"
TRT="libnvinfer.so.11 libnvinfer_plugin.so.11 libnvonnxparser.so.11
     libnppc.so.13 libnppig.so.13 liblibrediffusion.so"

# /var/tmp, not /tmp: an extracted AppDir is a couple of GB and /tmp is a tmpfs
# on our builders, so the default would spend that in RAM.
TMP="$(mktemp -d -p "${TMPDIR:-/var/tmp}")"
trap 'rm -rf "$TMP"' EXIT

if [[ ! -d "$RUNTIME" ]]; then
  echo "error: no such GPU runtime source: $RUNTIME" >&2
  exit 2
fi

REPACK_TO=""
if [[ -f "$TARGET" ]]; then
  REPACK_TO="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"
  ( cd "$TMP" && APPIMAGE_EXTRACT_AND_RUN=1 "$REPACK_TO" --appimage-extract >/dev/null )
  APPDIR="$TMP/squashfs-root"
else
  APPDIR="$TARGET"
fi

if [[ ! -d "$APPDIR" ]]; then
  echo "error: no such package: $TARGET" >&2
  exit 2
fi

LIB="$APPDIR/usr/lib"
if [[ ! -d "$LIB" ]]; then
  echo "error: $TARGET does not look like a packaged Koaia (no usr/lib)" >&2
  exit 1
fi

removed=0
for f in $LIBXCB_PKG; do
  [[ -e "$LIB/$f" ]] && { rm -f "$LIB/$f"; removed=$((removed + 1)); }
done
echo "xcb: removed $removed libxcb-package libs, kept $(find "$LIB" -maxdepth 1 -name 'libxcb-*' | wc -l) others"

# A missing GPU library is a hard failure: shipping the package anyway is what
# this script exists to stop. The builder resources are matched by glob because
# their names carry the TensorRT patch version.
missing=()
staged=0
for f in $CUDA_CORE $CUDNN $TRT; do
  src="$(find "$RUNTIME" -name "$f" -print -quit 2>/dev/null || true)"
  if [[ -n "$src" ]]; then
    cp -aL "$src" "$LIB/"
    staged=$((staged + 1))
  else
    missing+=("$f")
  fi
done

res=0
while IFS= read -r src; do
  cp -aL "$src" "$LIB/"
  res=$((res + 1))
done < <(find "$RUNTIME" -name 'libnvinfer_builder_resource*' 2>/dev/null)

if ((${#missing[@]})); then
  echo "error: missing from the GPU runtime at $RUNTIME:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi
if ((res == 0)); then
  echo "error: no libnvinfer_builder_resource* in $RUNTIME — TensorRT could not build engines" >&2
  exit 1
fi
echo "gpu: staged $staged libraries and $res builder resources"

if [[ -n "$REPACK_TO" ]]; then
  TOOL="${APPIMAGETOOL:-}"
  if [[ -z "$TOOL" ]]; then
    TOOL="$(command -v appimagetool || true)"
  fi
  if [[ -z "$TOOL" ]]; then
    echo "error: appimagetool not found; set \$APPIMAGETOOL" >&2
    exit 1
  fi
  ( cd "$TMP" && APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" -n squashfs-root "$REPACK_TO" >/dev/null 2>&1 )
  echo "repacked: $REPACK_TO ($(( $(stat -c %s "$REPACK_TO") / 1048576 )) MB)"
fi
