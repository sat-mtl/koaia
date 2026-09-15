#!/usr/bin/env bash
# Fetch the uv binary into score/engine-builder/ so it ships inside the package.
#
# uv is ~45 MB per platform, so it is downloaded at package time rather than
# committed; score/.gitignore keeps the result out of the repo. Run this before
# create-app.sh / package-custom-app, once per target platform.
#
#   scripts/fetch-uv.sh linux     -> score/engine-builder/uv
#   scripts/fetch-uv.sh windows   -> score/engine-builder/uv.exe
set -euo pipefail

# Pinned rather than "latest": the engine build is certified against this uv, and a
# resolver change upstream would silently alter the environment uv sync produces.
UV_VERSION="${UV_VERSION:-0.12.9}"

PLATFORM="${1:-linux}"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/score/engine-builder"
mkdir -p "$DEST"

case "$PLATFORM" in
    linux)   ASSET="uv-x86_64-unknown-linux-gnu.tar.gz"; BIN="uv" ;;
    windows) ASSET="uv-x86_64-pc-windows-msvc.zip";      BIN="uv.exe" ;;
    *) echo "usage: $0 {linux|windows}" >&2; exit 2 ;;
esac

URL="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${ASSET}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching uv ${UV_VERSION} for ${PLATFORM}..."
curl -fsSL -o "$TMP/$ASSET" "$URL"

case "$ASSET" in
    *.tar.gz) tar xzf "$TMP/$ASSET" -C "$TMP" ;;
    *.zip)    unzip -q "$TMP/$ASSET" -d "$TMP" ;;
esac

# The archives nest the binary one directory deep (linux) or place it at the root
# (windows), so find it rather than assuming a layout.
FOUND="$(find "$TMP" -type f -name "$BIN" -print -quit)"
[[ -n "$FOUND" ]] || { echo "error: $BIN not found in $ASSET" >&2; exit 1; }

install -m 755 "$FOUND" "$DEST/$BIN"
echo "-> $DEST/$BIN ($(du -h "$DEST/$BIN" | cut -f1))"
