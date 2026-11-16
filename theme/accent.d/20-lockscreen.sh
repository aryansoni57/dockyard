#!/bin/sh
# Lock screen: the accent and its companion (a hue shifted ~25 degrees) in the installed look-and-feel copies.
data="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/look-and-feel"
python3 - "$ACCENT" "$data" <<'PY'
import colorsys, glob, re, sys
accent, root = sys.argv[1], sys.argv[2]
r, g, b = (int(accent[i:i + 2], 16) / 255 for i in (1, 3, 5))
h, l, s = colorsys.rgb_to_hls(r, g, b)
r2, g2, b2 = colorsys.hls_to_rgb((h + 0.07) % 1, l, s)
second = "#%02x%02x%02x" % (round(r2 * 255), round(g2 * 255), round(b2 * 255))
for f in glob.glob(root + "/dev.aryan.dockyard*/contents/lockscreen/LockScreenUi.qml"):
    t = open(f).read()
    n = re.sub(r'(readonly property color accent: )"#[0-9a-fA-F]{6}"', r'\1"%s"' % accent, t)
    n = re.sub(r'(readonly property color accent2: )"#[0-9a-fA-F]{6}"', r'\1"%s"' % second, n)
    if n != t:
        open(f, "w").write(n)
PY
