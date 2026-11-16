#!/usr/bin/env bash
# Re-render the app icon PNGs from the SVG (needs rsvg-convert). Run after editing the SVG.
set -euo pipefail
d="$(cd "$(dirname "$0")" && pwd)"
n=dev.aryan.dockyard.settings
mkdir -p "$d/hicolor/scalable/apps"
cp "$d/$n.svg" "$d/hicolor/scalable/apps/$n.svg"
for s in 16 22 24 32 48 64 128 256; do
    mkdir -p "$d/hicolor/${s}x${s}/apps"
    rsvg-convert -w "$s" -h "$s" "$d/$n.svg" -o "$d/hicolor/${s}x${s}/apps/$n.png"
done
