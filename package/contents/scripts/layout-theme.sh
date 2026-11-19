#!/bin/sh
# Switch the Dockyard look between one bar and floating islands. A Plasma panel draws
# its own background; for islands the dock needs that background gone, so this builds
# "glass-islands" (a copy of the installed glass theme whose panel backgrounds are
# fully transparent) and applies it. "bar" puts glass or glass-opaque back.
# The Day set works the same way: glass-day-islands from glass-day, and glass-day or
# glass-day-opaque for the bar. The active theme picks the set; DOCKYARD_TONE=day|night
# picks it instead (day-night.sh uses this to switch set and layout in one step).
# Only acts when a Dockyard Plasma theme is active, so another theme is never replaced.
# Usage: layout-theme.sh islands|bar [opaque|frosted]
mode="$1"
case "$mode" in
    islands|bar) ;;
    *) echo "usage: $0 islands|bar [opaque|frosted]" >&2; exit 1 ;;
esac
cur=$(kreadconfig6 --file plasmarc --group Theme --key name)
case "$cur" in
    glass|glass-opaque|glass-islands) family=glass ;;
    glass-day|glass-day-opaque|glass-day-islands) family=glass-day ;;
    *) echo "active theme is '$cur', left alone"; exit 0 ;;
esac
case "$DOCKYARD_TONE" in
    day) family=glass-day ;;
    night) family=glass ;;
esac
base="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme"

if [ "$mode" = bar ]; then
    want="$family"
    [ "$2" = opaque ] && want="$family-opaque"
    [ -d "$base/$want" ] || [ -d "/usr/share/plasma/desktoptheme/$want" ] || { echo "theme $want is not installed" >&2; exit 1; }
    exec plasma-apply-desktoptheme "$want"
fi

src="$base/$family"
[ -d "$src" ] || src="/usr/share/plasma/desktoptheme/$family"
[ -d "$src" ] || { echo "theme $family is not installed; run install-all.sh" >&2; exit 1; }
command -v python3 >/dev/null || exit 1
rm -rf "$base/$family-islands"
cp -r "$src" "$base/$family-islands"
python3 - "$base/$family-islands" "$family" <<'PY'
import glob, json, os, re, sys
root, family = sys.argv[1], sys.argv[2]
# Keep the 9-slice ids and margin hints, but draw nothing and ask for no blur.
for path in glob.glob(os.path.join(root, "**", "panel-background.svg"), recursive=True):
    s = open(path, encoding="utf-8").read()
    s = re.sub(r'fill-opacity="[^"]*"', 'fill-opacity="0"', s)
    # Blur only four 1px corners. A missing or empty mask makes the panel blur its whole window (a
    # saturated slab around the pills); a stretched centre or edge would blur a band. Done after the
    # fill-opacity pass above, which would otherwise zero these too.
    corners = ("mask-topleft", "mask-topright", "mask-bottomleft", "mask-bottomright")
    s = re.sub(r'<g id="(mask-[^"]*)">.*?</g>',
               lambda m: '<g id="%s"><rect x="0" y="0" width="1" height="1" fill="#000" fill-opacity="%s"/></g>'
                         % (m.group(1), "1" if m.group(1) in corners else "0"), s, flags=re.S)
    # No background also means no panel margins: pills sit flush with the panel edges.
    s = re.sub(r'(<rect id="hint-(?:left|right)-margin"[^>]*?width=")[^"]*"', r'\g<1>0"', s)
    s = re.sub(r'(<rect id="hint-(?:top|bottom)-margin"[^>]*?height=")[^"]*"', r'\g<1>0"', s)
    open(path, "w", encoding="utf-8").write(s)
# A panel also insets each applet by the widget background's top and bottom margins, which would
# leave a strip above and below the pills. Zero those two (left and right are left alone).
for path in glob.glob(os.path.join(root, "**", "widgets", "background.svg"), recursive=True):
    s = open(path, encoding="utf-8").read()
    s = re.sub(r'(<rect id="hint-(?:top|bottom)-margin"[^>]*?height=")[^"]*"', r'\g<1>0"', s)
    open(path, "w", encoding="utf-8").write(s)
# No blur behind the panel window: the pills are drawn in QML, so a blurred panel rect would
# show as a slab around them.
open(os.path.join(root, "plasmarc"), "a", encoding="utf-8").write("\n[BlurBehind]\nenabled=false\n\n[ContrastEffect]\nenabled=false\n")
meta = os.path.join(root, "metadata.json")
d = json.load(open(meta, encoding="utf-8"))
day = family == "glass-day"
d["KPlugin"]["Id"] = family + "-islands"
d["KPlugin"]["Name"] = "Glass Day (islands)" if day else "Glass (islands)"
d["KPlugin"]["Description"] = ("Glass Day" if day else "Glass") + " with no panel background, for the Dockyard island layout. Made by Dockyard."
json.dump(d, open(meta, "w", encoding="utf-8"), indent=4)
PY
exec plasma-apply-desktoptheme "$family-islands"
