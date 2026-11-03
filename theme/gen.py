#!/usr/bin/env python3
"""Generate the 'glass' Plasma desktop theme into theme/glass/. Tokens: docs/mockups/theme-desktop-tokens.md"""
import os, json, sys

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "glass")
GLASS = "#16161a"
RIMS = RIM = 'stroke="#ffffff" stroke-opacity="0.14" stroke-width="1" fill="none"'
RIM_TOP = 'stroke="#ffffff" stroke-opacity="0.22" stroke-width="1" fill="none"'


def frame(R, alpha, margin, top_lit=False, rim=True, stretch=False):
    """9-slice rounded frame: fill + 1px rim, mask-* copy for KWin blur, margin hints."""
    S = 2 * R + 8
    a, b = R, R + 8
    f = f'fill="{GLASS}" fill-opacity="{alpha}"'
    RIM = RIMS if rim else 'fill="none" stroke="none"'
    rim_t = RIM_TOP if (top_lit and rim) else RIM
    rect = lambda x, y, w, h: f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {f}/>'
    ln = lambda x1, y1, x2, y2, st=RIM: f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" {st}/>'
    arc = lambda d, st=RIM: f'<path d="{d}" {st}/>'
    fill = lambda d: f'<path d="{d}" {f}/>'
    h = R - 0.5
    parts = {
        "center": rect(a, a, 8, 8),
        "top": rect(a, 0, 8, R) + ln(a, .5, b, .5, rim_t),
        "bottom": rect(a, b, 8, R) + ln(a, S - .5, b, S - .5),
        "left": rect(0, a, R, 8) + ln(.5, a, .5, b),
        "right": rect(b, a, R, 8) + ln(S - .5, a, S - .5, b),
        "topleft": fill(f"M{R},0 A{R},{R} 0 0 0 0,{R} L{R},{R} Z") + arc(f"M{R},.5 A{h},{h} 0 0 0 .5,{R}", rim_t),
        "topright": fill(f"M{b},0 A{R},{R} 0 0 1 {S},{R} L{b},{R} Z") + arc(f"M{b},.5 A{h},{h} 0 0 1 {S-.5},{R}", rim_t),
        "bottomleft": fill(f"M{R},{S} A{R},{R} 0 0 1 0,{b} L{R},{b} Z") + arc(f"M{R},{S-.5} A{h},{h} 0 0 1 .5,{b}"),
        "bottomright": fill(f"M{b},{S} A{R},{R} 0 0 0 {S},{b} L{b},{b} Z") + arc(f"M{b},{S-.5} A{h},{h} 0 0 0 {S-.5},{b}"),
    }
    body = "".join(f'<g id="{k}">{v}</g>' for k, v in parts.items())
    mask = "".join(f'<g id="mask-{k}">{v}</g>' for k, v in parts.items())
    mask = mask.replace(f, 'fill="#000"').replace(RIM, 'fill="none" stroke="none"').replace(RIM_TOP, 'fill="none" stroke="none"')
    m = margin
    hints = (
        ('<rect id="hint-stretch-borders" width="1" height="1" fill="none"/>' if stretch else '') +
        '<rect id="hint-tile-center" width="1" height="1" fill="none"/>'
        f'<rect id="hint-left-margin" x="0" y="0" width="{m}" height="1" fill="none"/>'
        f'<rect id="hint-right-margin" x="0" y="0" width="{m}" height="1" fill="none"/>'
        f'<rect id="hint-top-margin" x="0" y="0" width="1" height="{m}" fill="none"/>'
        f'<rect id="hint-bottom-margin" x="0" y="0" width="1" height="{m}" fill="none"/>'
    )
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">'
            f'{body}{mask}{hints}</svg>')


def write(path, text):
    p = os.path.join(OUT, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(text)


# (file, radius, alpha, margin, top-lit)
SURFACES = [
    ("dialogs/background.svg", 20, 0.62, 12, False),
    ("widgets/background.svg", 16, 0.62, 12, False),
    ("widgets/tooltip.svg", 10, 0.62, 8, False),
    ("widgets/panel-background.svg", 12, 0.55, 8, False),
]

for path, R, alpha, margin, lit in SURFACES:
    panel = "panel" in path
    svg = frame(R, alpha, margin, lit, rim=not panel, stretch=panel)
    write("translucent/" + path, svg)
    # base: compositing without blur, so keep text readable on the wallpaper
    write(path, frame(R, 0.90, margin, lit, rim=not panel, stretch=panel))
    # opaque/ (no compositing) and solid/ (adaptive panel under a window, tooltips, menus)
    write("opaque/" + path, frame(R, 0.96, margin, lit, rim=not panel, stretch=panel))
    write("solid/" + path, frame(R, 0.96, margin, lit, rim=not panel, stretch=panel))


def rgb(h):
    h = h.lstrip("#")
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def group(name, bg, alt, accent="#0A84FF"):
    return f"""[Colors:{name}]
BackgroundAlternate={rgb(alt)}
BackgroundNormal={rgb(bg)}
DecorationFocus={rgb(accent)}
DecorationHover={rgb(accent)}
ForegroundActive={rgb(accent)}
ForegroundInactive=162,162,163
ForegroundLink=100,210,255
ForegroundNegative=255,59,48
ForegroundNeutral=255,159,10
ForegroundNormal=255,255,255
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242
"""


colors = """[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

"""
colors += group("Button", "#3d3d40", "#4a4a4e")
colors += group("Complementary", "#16161a", "#1e1e23")
colors += group("Header", "#1e1e23", "#16161a")
colors += group("Selection", "#0071e3", "#0071e3", "#ffffff").replace(
    "ForegroundInactive=162,162,163", "ForegroundInactive=230,230,235").replace(
    "ForegroundLink=100,210,255", "ForegroundLink=255,255,255")
colors += group("Tooltip", "#16161a", "#1e1e23")
colors += group("View", "#16161a", "#1e1e23")
colors += group("Window", "#16161a", "#1e1e23")
write("colors", colors)

write("metadata.json", json.dumps({
    "KPackageStructure": "Plasma/Theme",
    "KPlugin": {
        "Authors": [{"Name": "aryan"}],
        "Category": "Plasma Theme",
        "Description": "Frosted dark glass: popups, notifications, tooltips and panels matching Dockyard",
        "EnabledByDefault": True,
        "Id": "glass",
        "Name": "Glass",
        "Version": "1.0",
        "License": "GPL-2.0+",
    },
}, indent=4))
print("wrote", OUT)
