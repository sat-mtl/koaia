#!/bin/bash
# Launcher script for Koaia Pro
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/Koaia-Pro-linux-x86_64.AppImage" "$@"
