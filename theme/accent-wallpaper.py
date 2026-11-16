#!/usr/bin/env python3
"""Render a Dockyard wallpaper in the accent hue: dark (or light) gradient with soft diagonal ribbons,
the same look as the Dockyard Settings backdrop.

Usage: accent-wallpaper.py [#rrggbb] [--day] [--size 3840x2160] [--out file.png] [--apply]
Default accent: the system accent. Default output: ~/.local/share/wallpapers/Dockyard-accent/contents/images/<size>.png
--apply sets it as the desktop wallpaper (plasma-apply-wallpaperimage); without it nothing on the desktop changes.
"""
import colorsys, os, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter

args = sys.argv[1:]
day = "--day" in args
apply = "--apply" in args
size = (3840, 2160)
out = None
accent = None
i = 0
while i < len(args):
    a = args[i]
    if a == "--size":
        size = tuple(int(v) for v in args[i + 1].lower().split("x")); i += 1
    elif a == "--out":
        out = args[i + 1]; i += 1
    elif a.startswith("#") and len(a) == 7:
        accent = a
    i += 1
if accent is None:
    r = subprocess.run(["kreadconfig6", "--file", "kdeglobals", "--group", "General", "--key", "AccentColor"], capture_output=True, text=True).stdout.strip()
    if not r:
        r = subprocess.run(["kreadconfig6", "--file", "kdeglobals", "--group", "Colors:Window", "--key", "DecorationFocus"], capture_output=True, text=True).stdout.strip()
    accent = "#%02x%02x%02x" % tuple(int(v) for v in r.split(",")[:3]) if r.count(",") == 2 else "#3b82f6"
h, _, s = colorsys.rgb_to_hls(*(int(accent[i:i + 2], 16) / 255 for i in (1, 3, 5)))
s = max(s, 0.15) if s > 0.12 else s          # keep a grey accent grey

def col(dh, sat, light, a=1.0):
    r, g, b = colorsys.hls_to_rgb((h + dh) % 1, light, min(1, sat * s * 1.3) if s else 0)
    return (round(r * 255), round(g * 255), round(b * 255), round(a * 255))

W, H = size
base = Image.new("RGBA", size)
d = ImageDraw.Draw(base)
top, bot = (col(0, 0.6, 0.10), col(0, 0.7, 0.05)) if not day else (col(0, 0.8, 0.96), col(-0.04, 0.7, 0.93))
for y in range(H):
    t = y / (H - 1)
    d.line([(0, y), (W, y)], fill=tuple(round(top[k] + (bot[k] - top[k]) * t) for k in range(4)))
ribbons = [(-0.3, 0.15, 1.5, 0.14, 0.55, 0.0, 0.02), (-0.1, 0.62, 1.3, 0.07, 0.5, 0.02, -0.06), (0.3, -0.1, 1.0, 0.24, 0.42, -0.07, 0.03)]
for x, y, w, hgt, op, d1, d2 in ribbons:
    rw, rh = int(W * w), int(H * hgt)
    c1 = col(d1, 0.65, 0.42 if not day else 0.82)
    c2 = col(d2, 0.95, 0.65 if not day else 0.84)
    ribbon = Image.new("RGBA", (rw, rh))
    rd = ImageDraw.Draw(ribbon)
    for px in range(rw):
        t = px / rw
        if t < 0.35: a = t / 0.35; c = c1
        elif t < 0.7: k = (t - 0.35) / 0.35; c = tuple(round(c1[j] + (c2[j] - c1[j]) * k) for j in range(3)) + (255,); a = 1
        else: a = (1 - t) / 0.3; c = c2
        rd.line([(px, 0), (px, rh)], fill=c[:3] + (round(255 * op * a),))
    mask = Image.new("L", (rw, rh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, rw - 1, rh - 1], radius=rh // 2, fill=255)
    ribbon.putalpha(Image.composite(ribbon.getchannel("A"), Image.new("L", (rw, rh), 0), mask))
    ribbon = ribbon.rotate(28, expand=True, resample=Image.BICUBIC)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    layer.paste(ribbon, (int(W * x) - (ribbon.width - rw) // 2, int(H * y) - (ribbon.height - rh) // 2), ribbon)
    base = Image.alpha_composite(base, layer.filter(ImageFilter.GaussianBlur(W // 160)))
if out is None:
    folder = os.path.expanduser("~/.local/share/wallpapers/Dockyard-accent/contents/images")
    os.makedirs(folder, exist_ok=True)
    out = os.path.join(folder, f"{W}x{H}.png")
base.convert("RGB").save(out)
print(out)
if apply:
    subprocess.run(["plasma-apply-wallpaperimage", out], check=False)
