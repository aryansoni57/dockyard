#!/bin/sh
# GTK apps: the desktop accent name (GNOME 47+ apps), and libadwaita / GTK 3 colour overrides in a
# marked block of ~/.config/gtk-{3.0,4.0}/gtk.css (the rest of those files is left alone).
python3 - "$ACCENT" <<'PY'
import colorsys, os, re, subprocess, sys
accent = sys.argv[1]
r, g, b = (int(accent[i:i + 2], 16) / 255 for i in (1, 3, 5))
h, l, s = colorsys.rgb_to_hls(r, g, b)
deg = h * 360
if s < 0.18:
    name = "slate"
else:
    names = [("red", 5), ("orange", 28), ("yellow", 48), ("green", 135), ("teal", 175), ("blue", 215), ("purple", 275), ("pink", 330), ("red", 360)]
    name = min(names, key=lambda n: abs(n[1] - deg))[0]
try:
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "accent-color", name], check=False, timeout=5)
except Exception:
    pass
# accent as a fill under white text (AA), and as text on a dark or light window
def toward(c, target, bg, ratio):
    def lin(v): return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    def lum(c): return 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2])
    def con(a, b_): la, lb = lum(a), lum(b_); return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    for i in range(41):
        k = i / 40
        x = tuple(c[j] + (target[j] - c[j]) * k for j in range(3))
        if con(x, bg) >= ratio:
            return "#%02x%02x%02x" % tuple(round(v * 255) for v in x)
    return "#%02x%02x%02x" % tuple(round(v * 255) for v in target)
c = (r, g, b)
bg = toward(c, (0, 0, 0), (1, 1, 1), 4.5)
text = toward(c, (1, 1, 1), (0.09, 0.09, 0.1), 4.5)
block = ("/* dockyard-accent begin */\n"
         f"@define-color accent_bg_color {bg};\n@define-color accent_fg_color #ffffff;\n@define-color accent_color {text};\n"
         f"@define-color theme_selected_bg_color {bg};\n@define-color theme_selected_fg_color #ffffff;\n"
         "/* dockyard-accent end */\n")
for v in ("gtk-3.0", "gtk-4.0"):
    d = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), v)
    if not os.path.isdir(d):
        continue
    f = os.path.join(d, "gtk.css")
    t = open(f).read() if os.path.exists(f) else ""
    t = re.sub(r"/\* dockyard-accent begin \*/.*?/\* dockyard-accent end \*/\n?", "", t, flags=re.S)
    open(f, "w").write(t.rstrip("\n") + ("\n\n" if t.strip() else "") + block)
PY
