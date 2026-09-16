#!/usr/bin/env bash
# Stage everything the packaged app needs that is not tracked in this repo, then
# hand off to create-app.sh / package-custom-app.
#
#   scripts/prepare-package.sh {linux|windows}
#
# Two jobs:
#
# 1. Copy librediffusion's Python engine builder into score/engine-builder/.
#    create-app.sh copies the whole directory holding the score file into the
#    package, so anything landed there ships. It is staged rather than committed
#    because it is a copy of 3rdparty/librediffusion, which is the submodule of
#    record.
#
#    train-lora.py is NOT self-contained: it does its own sys.path.insert for
#    <dir>/src (line 33) and <dir>/tools (line 54), then imports streamdiffusion
#    throughout and export_ipadapter_image_encoder from tools/. Shipping the
#    script alone cannot work, and uv sync will not rescue it -- uv.lock records
#    the project as `source = { virtual = "." }`, so uv never installs it and
#    nothing else puts streamdiffusion on the path.
#
# 2. Fetch the uv binary (see fetch-uv.sh).
set -euo pipefail

PLATFORM="${1:-linux}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/3rdparty/librediffusion"
DEST="$ROOT/score/engine-builder"

if [[ ! -f "$SRC/train-lora.py" ]]; then
    echo "error: $SRC is empty -- run: git submodule update --init 3rdparty/librediffusion" >&2
    exit 1
fi

# Warn by default rather than fail: the addon's pin moves in a different repo, so a
# hard failure here turns an ordinary cross-repo lag into a broken koaia build. Set
# KOAIA_STRICT_PIN=1 (release builds) to make a mismatch fatal.
if ! "$ROOT/scripts/check-librediffusion-pin.sh"; then
    if [[ "${KOAIA_STRICT_PIN:-0}" == "1" ]]; then
        echo "error: librediffusion pin mismatch and KOAIA_STRICT_PIN=1" >&2
        exit 1
    fi
    echo "warning: continuing despite the librediffusion pin mismatch above" >&2
fi

rm -rf "$DEST"
mkdir -p "$DEST"
for f in train-lora.py pyproject.toml uv.lock README.md; do
    cp "$SRC/$f" "$DEST/$f"
done
# src/streamdiffusion whole: train-lora.py imports across most of it, and
# klein/assets (~15 MB of the 17 MB) is loaded at build time by the klein path.
cp -r "$SRC/src/streamdiffusion" "$DEST/src-streamdiffusion-tmp"
mkdir -p "$DEST/src"
mv "$DEST/src-streamdiffusion-tmp" "$DEST/src/streamdiffusion"
mkdir -p "$DEST/tools"
cp "$SRC"/tools/*.py "$DEST/tools/"

echo "staged engine-builder from $(git -C "$SRC" rev-parse --short=9 HEAD): $(du -sh "$DEST" | cut -f1)"

"$ROOT/scripts/fetch-uv.sh" "$PLATFORM"
