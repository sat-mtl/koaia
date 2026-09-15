#!/usr/bin/env bash
# Re-copy the engine-builder sources from a librediffusion checkout.
#
# score/engine-builder/ is a COPY of the Python engine-build tooling from
# github.com/jcelerier/librediffusion, taken so the shipped package carries it
# directly instead of installing it through score's package manager. Because it
# is a copy it can drift: re-run this against a fresh checkout whenever the
# upstream build script or its pinned dependency set changes.
#
# Last synced from librediffusion 2a230dc91a2fe0a2f821c6d958f4720013712e96
#
#   scripts/sync-engine-builder.sh /path/to/librediffusion
set -euo pipefail

SRC="${1:?usage: $0 /path/to/librediffusion}"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/score/engine-builder"

# README.md is listed as the project readme in pyproject.toml, so it travels with it.
for f in train-lora.py pyproject.toml uv.lock README.md; do
    [[ -f "$SRC/$f" ]] || { echo "error: $SRC/$f missing" >&2; exit 1; }
    cp "$SRC/$f" "$DEST/$f"
done

echo "Synced from $SRC ($(cd "$SRC" && git rev-parse --short HEAD 2>/dev/null || echo 'not a git checkout'))"
echo "Update the 'Last synced' line in this script."
