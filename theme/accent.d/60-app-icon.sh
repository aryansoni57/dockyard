#!/bin/sh
# Dockyard Settings app icon: the rose gear and tile take the accent (light and dark companions),
# rendered from the repo SVG into the user icon theme. The repo SVG keeps the rose original.
src="$(cd "$(dirname "$0")/../../settings/icons/app" && pwd)/dev.aryan.dockyard.settings.svg"
dst="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
[ -f "$src" ] && command -v rsvg-convert >/dev/null || exit 0
tmp=$(mktemp --suffix=.svg)
python3 - "$ACCENT" "$src" "$tmp" <<'PY'
import colorsys, sys
accent, src, out = sys.argv[1:4]
r, g, b = (int(accent[i:i + 2], 16) / 255 for i in (1, 3, 5))
h, l, s = colorsys.rgb_to_hls(r, g, b)
def hexof(li):
    x = colorsys.hls_to_rgb(h, max(0, min(1, li)), s)
    return "#%02x%02x%02x" % tuple(round(v * 255) for v in x)
t = open(src).read()
for old, new in (("#e03f78", hexof(l - 0.08)), ("#ec4f86", accent), ("#ff8ab3", hexof(l + 0.16))):
    t = t.replace(old, new)
open(out, "w").write(t)
PY
n=dev.aryan.dockyard.settings
mkdir -p "$dst/scalable/apps"
cp "$tmp" "$dst/scalable/apps/$n.svg"
for s in 16 22 24 32 48 64 128 256; do
    mkdir -p "$dst/${s}x${s}/apps"
    rsvg-convert -w "$s" -h "$s" "$tmp" -o "$dst/${s}x${s}/apps/$n.png"
done
rm -f "$tmp"
gtk-update-icon-cache -f -t "$dst" >/dev/null 2>&1
kbuildsycoca6 >/dev/null 2>&1
# Tell running apps and plasmashell (the dock's task icons) the icon theme changed, one signal per icon size group.
for g in 0 1 2 3 4 5; do
    dbus-send --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:$g >/dev/null 2>&1
    dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:4 int32:$g >/dev/null 2>&1
done
