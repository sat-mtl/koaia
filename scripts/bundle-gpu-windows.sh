#!/usr/bin/env bash
# Stage the GPU runtime koaia needs — librediffusion plus CUDA 13, cuDNN 9 and
# TensorRT 11 — into an already-packaged Windows Koaia directory.
#
# WHY THIS EXISTS. score-addon-librediffusion never links librediffusion: it
# LoadLibrary's it at run time (see its CMakeLists, "loads the librediffusion
# runtime through its C API by dynamic loading"), so the packaged app-bin.exe
# imports none of this and `create-app-windows.sh` has nothing to copy. A package
# built without this step starts, shows the UI, and then cannot reach the GPU at
# all. Until now the DLLs were injected into the zip by hand after packaging,
# which means every repackage silently shipped a broken build unless somebody
# remembered.
#
# WHY AN IMPORT WALK IS NOT ENOUGH. Measured with objdump on the September
# reference package, librediffusion.dll's whole non-system import table is
#
#   nppig64_13.dll  nvinfer_11.dll  MSVCP140.dll  VCRUNTIME140.dll  VCRUNTIME140_1.dll
#
# and nvinfer_11.dll imports nothing but KERNEL32/USER32/SHELL32/ole32/ntdll.
# TensorRT dlopen()s the CUDA runtime, cuBLAS, cuFFT, cuRAND, cuDNN, nvrtc and
# nvJitLink instead of importing them, and cuDNN's cudnn64_9.dll is a dispatch
# shim that dlopen()s its own engine libraries — exactly the reason livepose's
# bundle-cuda-windows.sh ships the whole cuDNN bin/ rather than the one DLL its
# import table names. So the closure below is seeded from the import walk and
# completed with a named set, each entry justified.
#
# THE BUILDER RESOURCES ARE NOT OPTIONAL. nvinfer_builder_resource_{ptx,sm86,
# sm120}_11.dll are ~700 MB of the total and are dlopen()ed only when TensorRT
# builds an engine. Dropping them leaves a package that runs pre-built engines
# and silently cannot build new ones — on the 3090 (sm86), on Blackwell (sm120)
# and through the PTX fallback alike. koaia's whole BUILD view depends on them.
#
# WHAT IS DELIBERATELY NOT HERE: libc++.dll, libunwind.dll and
# libwinpthread-1.dll. Those come from the ossia SDK toolchain and score's own
# packaging already ships them.
#
# COST: about 2.4 GB staged, so roughly a 2 GB package.
#
# Usage: bundle-gpu-windows.sh <package-dir|package.zip> [runtime-dir|runtime.zip]
# The runtime source defaults to $KOAIA_GPU_RUNTIME. A .zip on either side is
# unpacked, and a package .zip is repacked in place.

set -euo pipefail

TARGET="${1:-}"
RUNTIME="${2:-${KOAIA_GPU_RUNTIME:-}}"

if [[ -z "$TARGET" || -z "$RUNTIME" ]]; then
  echo "usage: $0 <package-dir|package.zip> [runtime-dir|runtime.zip]" >&2
  echo "       the runtime source may also come from \$KOAIA_GPU_RUNTIME" >&2
  exit 2
fi

# git-bash on the Windows runners ships neither unzip nor zip, so go through
# whichever of unzip/zip/7z is actually present -- the same dance score's
# tools/create-app-windows.sh and livepose's bundle-cuda-windows.sh do.
SEVENZIP="$(command -v 7z || command -v 7za || true)"

unpack() {
  local zip="$1" dir="$2"
  mkdir -p "$dir"
  if command -v unzip >/dev/null 2>&1; then
    unzip -q -o "$zip" -d "$dir"
  elif [[ -n "$SEVENZIP" ]]; then
    "$SEVENZIP" x -y -o"$dir" "$zip" >/dev/null
  else
    echo "error: need unzip or 7z to read $zip" >&2
    exit 1
  fi
}

pack() {
  local dir="$1" zip="$2"
  rm -f "$zip"
  if command -v zip >/dev/null 2>&1; then
    (cd "$dir" && zip -qr "$zip" .)
  elif [[ -n "$SEVENZIP" ]]; then
    (cd "$dir" && "$SEVENZIP" a -tzip "$zip" . >/dev/null)
  else
    echo "error: need zip or 7z to write $zip" >&2
    exit 1
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPACK_ZIP=""
if [[ -f "$TARGET" && "$TARGET" == *.zip ]]; then
  REPACK_ZIP="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"
  PKG_DIR="$TMP/pkg"
  unpack "$REPACK_ZIP" "$PKG_DIR"
else
  PKG_DIR="$TARGET"
fi

if [[ ! -d "$PKG_DIR" ]]; then
  echo "error: no such package: $TARGET" >&2
  exit 2
fi

# create-app may nest the payload one level down.
if [[ ! -f "$PKG_DIR/app-bin.exe" ]]; then
  nested="$(find "$PKG_DIR" -maxdepth 2 -name app-bin.exe -print -quit)"
  [[ -n "$nested" ]] && PKG_DIR="$(dirname "$nested")"
fi
if [[ ! -f "$PKG_DIR/app-bin.exe" ]]; then
  echo "error: $TARGET does not look like a packaged Koaia (no app-bin.exe)" >&2
  exit 1
fi

if [[ -f "$RUNTIME" && "$RUNTIME" == *.zip ]]; then
  RUNTIME_DIR="$TMP/runtime"
  unpack "$RUNTIME" "$RUNTIME_DIR"
else
  RUNTIME_DIR="$RUNTIME"
fi
if [[ ! -d "$RUNTIME_DIR" ]]; then
  echo "error: no such GPU runtime source: $RUNTIME" >&2
  exit 2
fi

# The librediffusion C API entry point. Everything else is reached from it.
ROOT_DLL=librediffusion.dll

# dlopen()ed, so no import walk can find them. Grouped by who loads them.
DLOPEN_DLLS=(
  # TensorRT 11 loads the CUDA stack itself.
  cudart64_13.dll cublas64_13.dll cublasLt64_13.dll cufft64_12.dll
  curand64_10.dll cudnn64_9.dll nvrtc64_130_0.dll nvrtc-builtins64_133.dll
  nvJitLink_130_0.dll
  # cudnn64_9.dll is a dispatch shim; these are the engine libraries it loads.
  cudnn_adv64_9.dll cudnn_cnn64_9.dll cudnn_graph64_9.dll cudnn_heuristic64_9.dll
  cudnn_ops64_9.dll cudnn_engines_precompiled64_9.dll
  cudnn_engines_runtime_compiled64_9.dll
  # Loaded by TensorRT only while BUILDING an engine. ~700 MB, and without them
  # the BUILD view fails on every GPU generation.
  nvinfer_builder_resource_ptx_11.dll nvinfer_builder_resource_sm86_11.dll
  nvinfer_builder_resource_sm120_11.dll
  # Plugin registry and the ONNX parser, both loaded on demand by TensorRT.
  nvinfer_plugin_11.dll nvonnxparser_11.dll
  # NPP core: nppig64_13.dll resolves it at run time, not through its imports.
  nppc64_13.dll
)

# Non-system DLL prefixes. Anything outside this set is a Windows API DLL or part
# of score's own toolchain, and is not ours to stage.
is_ours() {
  case "${1,,}" in
    librediffusion.dll|cublas*|cudnn*|cudart*|cufft*|curand*|npp*|nvinfer*|nvonnxparser*|\
    nvrtc*|nvjitlink*|msvcp140.dll|vcruntime140*.dll) return 0 ;;
    *) return 1 ;;
  esac
}

OBJDUMP="$(command -v llvm-objdump || command -v objdump || true)"

imports_of() {
  [[ -n "$OBJDUMP" && -f "$1" ]] || return 0
  "$OBJDUMP" -p "$1" 2>/dev/null | sed -n 's/.*DLL Name: //p' | sort -u
}

# Where a given DLL lives in the runtime source. The NVIDIA archives nest under
# bin/ or bin/x64, so search rather than assume a layout.
find_in_runtime() {
  find "$RUNTIME_DIR" -type f -iname "$1" -print -quit
}

echo "Staging the GPU runtime into $PKG_DIR"
echo "  runtime source: $RUNTIME_DIR"
[[ -n "$OBJDUMP" ]] || echo "  warning: no objdump/llvm-objdump; staging the named set without an import walk" >&2

declare -A staged=()
missing=()

# Staged under the SOURCE file's own spelling, not the caller's: import tables
# name MSVCP140.dll in caps while the file on disk is msvcp140.dll, and shipping
# both spellings only looks the same on a case-insensitive filesystem.
stage_one() {
  local name="$1"
  [[ -n "${staged[${name,,}]:-}" ]] && return 0
  local src
  src="$(find_in_runtime "$name")"
  if [[ -z "$src" ]]; then
    missing+=("$name")
    return 1
  fi
  install -m 644 "$src" "$PKG_DIR/$(basename "$src")"
  staged[${name,,}]="$PKG_DIR/$(basename "$src")"
  return 0
}

# Breadth-first over the import graph, seeded with the root and the dlopen set.
queue=("$ROOT_DLL" "${DLOPEN_DLLS[@]}")
while (( ${#queue[@]} )); do
  dll="${queue[0]}"
  queue=("${queue[@]:1}")
  is_ours "$dll" || continue
  [[ -n "${staged[${dll,,}]:-}" ]] && continue
  stage_one "$dll" || continue
  while read -r dep; do
    [[ -n "$dep" ]] && queue+=("$dep")
  done < <(imports_of "$PKG_DIR/$dll")
done

if (( ${#missing[@]} )); then
  echo "error: not found in $RUNTIME_DIR: ${missing[*]}" >&2
  exit 1
fi

# Verify over everything now in the package, not just what was staged: this is
# what catches a librediffusion or TensorRT bump that adds a dependency the named
# set above does not know about.
if [[ -n "$OBJDUMP" ]]; then
  unresolved=()
  for dll in "$PKG_DIR"/*.dll; do
    while read -r dep; do
      is_ours "$dep" || continue
      [[ -f "$PKG_DIR/$dep" ]] || unresolved+=("$(basename "$dll") -> $dep")
    done < <(imports_of "$dll")
  done
  if (( ${#unresolved[@]} )); then
    printf 'error: unresolved after staging:\n' >&2
    printf '       %s\n' "${unresolved[@]}" >&2
    echo "       the pinned dlopen set is out of date for this runtime" >&2
    exit 1
  fi
  echo "  import closure satisfied"
fi

echo "  staged ${#staged[@]} DLLs"
echo "Package is now $(du -sm "$PKG_DIR" | cut -f1) MB"

if [[ -n "$REPACK_ZIP" ]]; then
  pack "$PKG_DIR" "$REPACK_ZIP"
  echo "Repacked $REPACK_ZIP ($(du -sm "$REPACK_ZIP" | cut -f1) MB)"
fi
