#!/usr/bin/env python3
"""Generate the Dockyard theme set into theme/. Tokens: docs/mockups/theme-desktop-tokens.md

  glass/, glass-opaque/                  Plasma desktop themes (frosted and solid dock bar)
  color-schemes/Dockyard.colors          KDE color scheme
  kvantum/Dockyard/                      Kvantum: solid windows, glass menus and tooltips
  kvantum/DockyardGlass/                 Kvantum: translucent windows too
  aurorae/Dockyard/                      Aurorae window decoration, monochrome buttons
  look-and-feel/dev.aryan.dockyard/      look-and-feel defaults that select the above

GLASS_THEME=glass-opaque writes only the solid Plasma theme.
"""
import base64, json, math, os, struct, subprocess, sys, zlib

BASE = os.path.dirname(os.path.abspath(__file__))

# "glass" is frosted. "glass-opaque" is the same theme with every surface solid, for
# the Opaque dock bar switch. The default run writes both, and the rest of the set.
NAME = os.environ.get("GLASS_THEME", "glass")
SOLID = NAME == "glass-opaque"
OUT = os.path.join(BASE, NAME)
GLASS = "#16161a"
HEADER = "#212128"
# App palette, for the color scheme and Kvantum. Plasma surfaces keep GLASS and white text.
VIEW = "#131317"     # sidebars and lists, the deepest level
VIEW_ALT = "#18181d"
WINDOW = "#1b1b21"   # pages and panels
BUTTON = "#2b2b33"
BUTTON_ALT = "#363640"
LINE = "#2e2e37"
APP_INK = "#ecedf2"      # softer than white, which glows on a dark ground
APP_INK_2 = "#a8a9b3"
SELECT = "#0071e3"  # selection and primary buttons; white text on it passes AA
RIM = 'fill="#ffffff" fill-opacity="0.14"'
RIM_TOP = 'fill="#ffffff" fill-opacity="0.08"'


def frame(R, alpha, margin, top_lit=False, rim=True, shadow=False):
    """9-slice rounded frame: fill + 1px rim, mask-* copy for KWin blur, margin hints.

    Rims are filled shapes, never strokes: a stroke widens the element's bounds, so
    KSvg draws the piece smaller than its slot and the frame shows gaps (dashes when
    tiled, missing runs by the corners when stretched, hairlines around the corners)."""
    S = 2 * R + 8
    a, b = R, R + 8
    r = R - 1
    f = f'fill="{GLASS}" fill-opacity="{alpha}"'
    rim_t = RIM_TOP if top_lit else RIM
    rect = lambda x, y, w, h: f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {f}/>'
    edge = lambda x, y, w, h, st=RIM: f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {st}/>' if rim else ''
    ring = lambda d, st=RIM: f'<path d="{d}" {st}/>' if rim else ''
    fill = lambda d: f'<path d="{d}" {f}/>'
    parts = {
        "center": rect(a, a, 8, 8),
        "top": rect(a, 0, 8, R) + edge(a, 0, 8, 1, rim_t),
        "bottom": rect(a, b, 8, R) + edge(a, S - 1, 8, 1),
        "left": rect(0, a, R, 8) + edge(0, a, 1, 8),
        "right": rect(b, a, R, 8) + edge(S - 1, a, 1, 8),
        "topleft": fill(f"M{R},0 A{R},{R} 0 0 0 0,{R} L{R},{R} Z")
            + ring(f"M{R},0 A{R},{R} 0 0 0 0,{R} L1,{R} A{r},{r} 0 0 1 {R},1 Z", rim_t),
        "topright": fill(f"M{b},0 A{R},{R} 0 0 1 {S},{R} L{b},{R} Z")
            + ring(f"M{b},0 A{R},{R} 0 0 1 {S},{R} L{S-1},{R} A{r},{r} 0 0 0 {b},1 Z", rim_t),
        "bottomleft": fill(f"M{R},{S} A{R},{R} 0 0 1 0,{b} L{R},{b} Z")
            + ring(f"M{R},{S} A{R},{R} 0 0 1 0,{b} L1,{b} A{r},{r} 0 0 0 {R},{S-1} Z"),
        "bottomright": fill(f"M{b},{S} A{R},{R} 0 0 0 {S},{b} L{b},{b} Z")
            + ring(f"M{b},{S} A{R},{R} 0 0 0 {S},{b} L{S-1},{b} A{r},{r} 0 0 1 {b},{S-1} Z"),
    }
    body = "".join(f'<g id="{k}">{v}</g>' for k, v in parts.items())
    mask = "".join(f'<g id="mask-{k}">{v}</g>' for k, v in parts.items())
    mask = mask.replace(f, 'fill="#000"').replace(RIM, 'fill="none"').replace(RIM_TOP, 'fill="none"')
    m = margin
    hints = (
        '<rect id="hint-stretch-borders" width="1" height="1" fill="none"/>'
        f'<rect id="hint-left-margin" x="0" y="0" width="{m}" height="1" fill="none"/>'
        f'<rect id="hint-right-margin" x="0" y="0" width="{m}" height="1" fill="none"/>'
        f'<rect id="hint-top-margin" x="0" y="0" width="1" height="{m}" fill="none"/>'
        f'<rect id="hint-bottom-margin" x="0" y="0" width="1" height="{m}" fill="none"/>'
    )
    # Plasma's QML ToolTip draws a "shadow" frame under the tooltip. Without shadow-*
    # elements KSvg falls back to the plain frame, so the tooltip shows twice.
    if shadow:
        hints += "".join(f'<g id="shadow-{k}"><rect width="1" height="1" fill="none"/></g>' for k in parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">'
            f'{body}{mask}{hints}</svg>')


def write(path, text):
    p = os.path.join(OUT, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(text)


def put(path, text):
    """Write under theme/ (not the Plasma theme folder)."""
    p = os.path.join(BASE, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(text)


# (file, radius, alpha, margin, top-lit)
SURFACES = [
    ("dialogs/background.svg", 20, 0.62, 12, False),
    ("widgets/background.svg", 16, 0.62, 12, False),
    ("widgets/tooltip.svg", 10, 0.10, 8, False),
    ("widgets/panel-background.svg", 12, 0.55, 8, False),
]

for path, R, alpha, margin, lit in SURFACES:
    panel = "panel" in path
    tip = "tooltip" in path
    if SOLID:
        alpha = 0.96
    kw = dict(rim=not panel, shadow=tip)
    svg = frame(R, alpha, margin, lit, **kw)
    write("translucent/" + path, svg)
    # base: compositing without blur, so keep text readable on the wallpaper
    # tooltips are nearly clear; the base fallback (no blur) stays more readable
    base = 0.40 if tip else 0.90
    write(path, frame(R, 0.96 if SOLID else base, margin, lit, **kw))
    # opaque/ (no compositing) and solid/ (adaptive panel under a window, menus)
    write("opaque/" + path, frame(R, 0.96, margin, lit, **kw))
    # Plasma's QML ToolTip always loads solid/widgets/tooltip and draws it inside the
    # applet's window, with no blur behind it: same alpha as the unblurred base
    write("solid/" + path, frame(R, 0.96 if SOLID or not tip else base, margin, lit, **kw))


def rgb(h):
    h = h.lstrip("#")
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def group(name, bg, alt, accent="#0A84FF", ink="#ffffff", ink_2="#a2a2a3"):
    return f"""[Colors:{name}]
BackgroundAlternate={rgb(alt)}
BackgroundNormal={rgb(bg)}
DecorationFocus={rgb(accent)}
DecorationHover={rgb(accent)}
ForegroundActive={rgb(accent)}
ForegroundInactive={rgb(ink_2)}
ForegroundLink=100,210,255
ForegroundNegative=255,59,48
ForegroundNeutral=255,159,10
ForegroundNormal={rgb(ink)}
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242
"""


effects = """[ColorEffects:Disabled]
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
colors = effects + group("Button", "#3d3d40", "#4a4a4e")
colors += group("Complementary", "#16161a", "#1e1e23")
colors += group("Header", "#1e1e23", "#16161a")
colors += group("Selection", "#0071e3", "#0071e3", "#ffffff").replace(
    "ForegroundInactive=162,162,163", "ForegroundInactive=230,230,235").replace(
    "ForegroundLink=100,210,255", "ForegroundLink=255,255,255")
colors += group("Tooltip", "#16161a", "#1e1e23")
colors += group("View", "#16161a", "#1e1e23")
colors += group("Window", "#16161a", "#1e1e23")
write("colors", colors)

app = lambda name, bg, alt: group(name, bg, alt, ink=APP_INK, ink_2=APP_INK_2)
app_colors = effects + app("Button", BUTTON, BUTTON_ALT)
app_colors += app("Complementary", "#16161a", "#1e1e23")
app_colors += app("Header", HEADER, WINDOW)
app_colors += group("Selection", SELECT, SELECT, "#ffffff").replace(
    "ForegroundInactive=162,162,163", "ForegroundInactive=230,230,235").replace(
    "ForegroundLink=100,210,255", "ForegroundLink=255,255,255")
app_colors += app("Tooltip", "#16161a", "#1e1e23")
app_colors += app("View", VIEW, VIEW_ALT)
app_colors += app("Window", WINDOW, HEADER)

write("metadata.json", json.dumps({
    "KPackageStructure": "Plasma/Theme",
    "KPlugin": {
        "Authors": [{"Name": "aryan"}],
        "Category": "Plasma Theme",
        "Description": ("Solid dark glass" if SOLID else "Frosted dark glass") + ": popups, notifications, tooltips and panels matching Dockyard",
        "EnabledByDefault": True,
        "Id": NAME,
        "Name": "Glass (opaque)" if SOLID else "Glass",
        "Version": "1.3",
        "License": "GPL-2.0+",
    },
}, indent=4))
print("wrote", OUT)

if NAME == "glass":
    subprocess.run([sys.executable, os.path.abspath(__file__)],
                   env={**os.environ, "GLASS_THEME": "glass-opaque"}, check=True)


# ---------------------------------------------------------------------------
# Dockyard set: KDE color scheme, Kvantum, Aurorae, look-and-feel.
# Every value below comes from the tokens above or the Dockyard tokens doc.
# ---------------------------------------------------------------------------

WHITE = (255, 255, 255)
PANEL = (22, 22, 26)           # GLASS as rgb
HEADER_RGB = (33, 33, 40)      # HEADER as rgb
HEADER_DIM = "#1b1b21"         # inactive titlebar
RIM_SOLID = "#37373a"          # rim flattened over GLASS, for window edges
ACC = (10, 132, 255)           # focus rings, slider fill, checked controls
SEL = (0, 113, 227)            # SELECT: selection and primary buttons
NEG = (255, 59, 48)
STATES = ("normal", "focused", "pressed", "toggled", "disabled")


def S(fill, a, rim=WHITE, ra=0.14):
    """One state of a Kvantum element: fill rgb and alpha, rim rgb and alpha."""
    return (fill, a, rim, ra)


def same(spec):
    return {s: spec for s in STATES}


def css(c):
    return f'rgb({",".join(map(str, c))})'


# Kvantum's "focused" state means the mouse is over the widget, except on line edits.
# Keyboard focus is drawn by the [Focus] frame.
BUTTON = {"normal": S(WHITE, .12), "focused": S(WHITE, .17), "pressed": S(WHITE, .22),
          "toggled": S(ACC, .35, ACC, .5), "disabled": S(WHITE, .06, WHITE, .08)}

# element: (corner radius, {state: S(...)})
KV = {
    "button": (10, BUTTON),
    "combo": (10, BUTTON),
    "lineedit": (10, {"normal": S(WHITE, .07, WHITE, .08), "focused": S(WHITE, .07, ACC, .7),
                      "pressed": S(WHITE, .07, WHITE, .08), "toggled": S(WHITE, .07, ACC, .7),
                      "disabled": S(WHITE, .04, WHITE, .06)}),
    "tab": (8, {"normal": S(WHITE, 0, WHITE, 0), "focused": S(WHITE, .06, WHITE, 0),
                "pressed": S(WHITE, .10, WHITE, 0), "toggled": S(WHITE, .12, WHITE, 0),
                "disabled": S(WHITE, 0, WHITE, 0)}),
    "tabframe": (12, same(S(WHITE, 0, WHITE, .08))),
    "common": (12, same(S(WHITE, 0, WHITE, .08))),
    "menu": (12, same(S(PANEL, .62, WHITE, .14))),
    "tooltip": (10, same(S(PANEL, .10, WHITE, .14))),
    "dock": (14, same(S(PANEL, .55, WHITE, .14))),
    "header": (2, same(S(HEADER_RGB, 1, WHITE, .08))),
    "itemview": (6, {"normal": S(WHITE, 0, WHITE, 0), "focused": S(WHITE, .06, WHITE, 0),
                     "pressed": S(ACC, .2, ACC, 0), "toggled": S(ACC, .2, ACC, 0),
                     "disabled": S(WHITE, 0, WHITE, 0)}),
    "menuitem": (6, {"normal": S(WHITE, 0, WHITE, 0), "focused": S(SEL, 1, SEL, 0),
                     "pressed": S(SEL, 1, SEL, 0), "toggled": S(SEL, 1, SEL, 0),
                     "disabled": S(WHITE, 0, WHITE, 0)}),
    "menubaritem": (6, {"normal": S(WHITE, 0, WHITE, 0), "focused": S(WHITE, .10, WHITE, 0),
                        "pressed": S(WHITE, .10, WHITE, 0), "toggled": S(WHITE, .10, WHITE, 0),
                        "disabled": S(WHITE, 0, WHITE, 0)}),
    "scrollbarslider": (4, {"normal": S(WHITE, .25, WHITE, 0), "focused": S(WHITE, .40, WHITE, 0),
                            "pressed": S(WHITE, .40, WHITE, 0), "toggled": S(WHITE, .40, WHITE, 0),
                            "disabled": S(WHITE, .10, WHITE, 0)}),
    "slider": (2, {**same(S(WHITE, .15, WHITE, 0)), "toggled": S(ACC, 1, ACC, 0)}),
    "progressbar": (4, same(S(WHITE, .15, WHITE, 0))),
    "progress": (4, same(S(ACC, 1, ACC, 0))),
}

TEXT = [f"text.normal.color={APP_INK}", f"text.focus.color={APP_INK}",
        f"text.press.color={APP_INK}", f"text.toggle.color={APP_INK}"]
MARGINS = ["text.margin.top=2", "text.margin.bottom=2", "text.margin.left=6", "text.margin.right=6"]

# Kvantum section -> element it draws with, and its own keys
KV_SECTIONS = [
    ("PanelButtonCommand", "button", ["indicator.element=arrow", "indicator.size=9", "text.iconspacing=4",
                                      "min_width=+0.3font", "min_height=+0.3font"] + MARGINS),
    ("PanelButtonTool", "menubaritem", ["indicator.element=arrow", "indicator.size=9"] + MARGINS),
    ("ToolbarButton", "menubaritem", ["indicator.element=tarrow", "indicator.size=9"] + MARGINS),
    ("ToolboxTab", "button", MARGINS),
    ("DropDownButton", "button", ["indicator.element=arrow-down", "indicator.size=9"]),
    ("IndicatorSpinBox", "button", ["indicator.element=spin", "indicator.size=9"]),
    ("ComboBox", "combo", ["indicator.element=carrow", "indicator.size=9"] + MARGINS),
    ("LineEdit", "lineedit", MARGINS),
    ("Tab", "tab", ["indicator.element=tab", "indicator.size=12", "text.margin.top=3", "text.margin.bottom=3",
                    "text.margin.left=8", "text.margin.right=8"]),
    ("TabFrame", "tabframe", []),
    ("GenericFrame", "common", []),
    ("GroupBox", "common", []),
    ("Menu", "menu", ["text.margin=4"]),
    ("MenuItem", "menuitem", ["indicator.element=arrow", "indicator.size=9"] + MARGINS),
    ("MenuBarItem", "menubaritem", MARGINS),
    ("ToolTip", "tooltip", ["text.margin=6"]),
    ("Dock", "dock", []),
    ("HeaderSection", "header", ["text.margin.left=6", "text.margin.right=6"]),
    ("ItemView", "itemview", ["text.margin=2"]),
    ("Slider", "slider", []),
    ("Progressbar", "progressbar", ["text.margin=0"]),
    ("ProgressbarContents", "progress", []),
    ("ScrollbarSlider", "scrollbarslider", []),
    ("Focus", "focus", []),
]

# Sections with no frame: they either show the window behind them or draw a single shape.
KV_PLAIN = [
    ("Toolbar", ["frame=false", "interior=false", "indicator.element=toolbar", "indicator.size=5"]),
    ("MenuBar", ["frame=false", "interior=false"]),
    ("StatusBar", ["frame=false", "interior=false"]),
    ("DockTitle", ["frame=false", "interior=false"]),
    ("TabBarFrame", ["frame=false", "interior=false"]),
    ("ScrollbarGroove", ["frame=false", "interior=false"]),
    ("Scrollbar", ["frame=false", "interior=false", "indicator.element=arrow", "indicator.size=9"]),
    ("Window", ["interior=true", "interior.element=window"]),
    ("TitleBar", ["frame=false", "interior=true", "interior.element=header-normal", "indicator.element=mdi",
                  "indicator.size=16", "text.bold=true"]),
    ("CheckBox", ["frame=false", "interior=true", "interior.element=checkbox"]),
    ("RadioButton", ["frame=false", "interior=true", "interior.element=radio"]),
    ("SliderCursor", ["frame=false", "interior=true", "interior.element=slidercursor"]),
    ("IndicatorArrow", ["indicator.element=arrow", "indicator.size=9"]),
    ("TreeExpander", ["indicator.element=tree", "indicator.size=12"]),
    ("SizeGrip", ["indicator.element=resize-grip"]),
    ("Splitter", ["indicator.element=splitter-grip", "indicator.size=48"]),
]


def kv_set(name, state, R, spec, oy):
    """One 9-slice set of Kvantum element `name` in `state`, drawn at y offset `oy`.

    Ids are <name>-<state>-<part>, with <name>-<state> for the interior. An empty state
    gives <name>-<part>, as [Focus] expects. Parts are drawn at absolute coordinates, not
    with transforms, so Kvantum reads their bounds."""
    fill, a, rim, ra = spec
    S_ = 2 * R + 8
    b0 = R + 8
    base = f"{name}-{state}" if state else name
    fa = f'fill="{css(fill)}" fill-opacity="{a}"'
    ra_s = f'fill="{css(rim)}" fill-opacity="{ra}"'
    pt = lambda x, y: f"{x},{y + oy}"
    rect = lambda x, y, w, h, s: f'<rect x="{x}" y="{y + oy}" width="{w}" height="{h}" {s}/>'
    path = lambda d, s: f'<path d="{d}" {s}/>'
    corner = {
        "topleft": (f"M{pt(R, 0)} A{R},{R} 0 0 0 {pt(0, R)} L{pt(R, R)} Z",
                    f"M{pt(R, 0)} A{R},{R} 0 0 0 {pt(0, R)} L{pt(1, R)} A{R-1},{R-1} 0 0 1 {pt(R, 1)} Z"),
        "topright": (f"M{pt(b0, 0)} A{R},{R} 0 0 1 {pt(S_, R)} L{pt(b0, R)} Z",
                     f"M{pt(b0, 0)} A{R},{R} 0 0 1 {pt(S_, R)} L{pt(S_-1, R)} A{R-1},{R-1} 0 0 0 {pt(b0, 1)} Z"),
        "bottomleft": (f"M{pt(R, S_)} A{R},{R} 0 0 1 {pt(0, b0)} L{pt(R, b0)} Z",
                       f"M{pt(R, S_)} A{R},{R} 0 0 1 {pt(0, b0)} L{pt(1, b0)} A{R-1},{R-1} 0 0 0 {pt(R, S_-1)} Z"),
        "bottomright": (f"M{pt(b0, S_)} A{R},{R} 0 0 0 {pt(S_, b0)} L{pt(b0, b0)} Z",
                        f"M{pt(b0, S_)} A{R},{R} 0 0 0 {pt(S_, b0)} L{pt(S_-1, b0)} A{R-1},{R-1} 0 0 1 {pt(b0, S_-1)} Z"),
    }
    out = []
    edges = {
        "center": rect(R, R, 8, 8, fa),
        "top": rect(R, 0, 8, R, fa) + rect(R, 0, 8, 1, ra_s),
        "bottom": rect(R, b0, 8, R, fa) + rect(R, S_ - 1, 8, 1, ra_s),
        "left": rect(0, R, R, 8, fa) + rect(0, R, 1, 8, ra_s),
        "right": rect(b0, R, R, 8, fa) + rect(S_ - 1, R, 1, 8, ra_s),
    }
    for part, body in edges.items():
        pid = base if part == "center" else f"{base}-{part}"
        out.append(f'<g id="{pid}">{body}</g>')
    for part, (fd, rd) in corner.items():
        out.append(f'<g id="{base}-{part}">{path(fd, fa)}{path(rd, ra_s)}</g>')
    return "".join(out), S_


INK = {"normal": .75, "focused": 1, "pressed": 1, "toggled": 1, "disabled": .3}
ARROWS = {"down": "M1,2.5 L4,5.5 L7,2.5", "up": "M1,5.5 L4,2.5 L7,5.5",
          "left": "M5.5,1 L2.5,4 L5.5,7", "right": "M2.5,1 L5.5,4 L2.5,7"}
# Glyphs on a 12 unit box
MDI = {"close": "M3,3 L9,9 M9,3 L3,9", "minimize": "M3,8 H9", "maximize": "M3,3 H9 V9 H3 Z",
       "restore": "M2.5,4.5 H7.5 V9.5 H2.5 Z M4.5,4.5 V2.5 H9.5 V7.5 H7.5"}


def kv_glyphs(oy):
    """Single shape elements: arrows, indicators, checkboxes, radios, slider knob.

    Each sits on an invisible box so its bounds are the full cell, whatever it draws."""
    cells, x, y = [], 0, 0
    step = 22

    def cell(gid, size, body):
        nonlocal x, y
        if x + step > 220:
            x, y = 0, y + step
        box = f'<rect width="{size}" height="{size}" fill="#ffffff" fill-opacity="0"/>'
        cells.append(f'<g id="{gid}"><g transform="translate({x},{y + oy})">{box}{body}</g></g>')
        x += step

    line = lambda d, a, w=1.6: (f'<path d="{d}" fill="none" stroke="#ffffff" stroke-opacity="{a}" '
                                f'stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
    for state in STATES:
        a = INK[state]
        for way, d in ARROWS.items():
            cell(f"arrow-{way}-{state}", 8, line(d, a))
            cell(f"tarrow-{way}-{state}", 8, line(d, a))
        cell(f"carrow-{state}", 8, line(ARROWS["down"], a))
        cell(f"tree-plus-{state}", 8, line(ARROWS["right"], a))
        cell(f"tree-minus-{state}", 8, line(ARROWS["down"], a))
    for state in ("normal", "focused", "pressed", "disabled"):
        a = INK[state]
        cell(f"spin-up-{state}", 8, line(ARROWS["up"], a))
        cell(f"spin-down-{state}", 8, line(ARROWS["down"], a))
        cell(f"spin-plus-{state}", 8, line("M1,4 H7 M4,1 V7", a))
        cell(f"spin-minus-{state}", 8, line("M1,4 H7", a))
        cell(f"tab-close-{state}", 12, line(MDI["close"], a, 1.3))
        for name, d in MDI.items():
            cell(f"mdi-{name}-{state}", 12, line(d, a, 1.2))

        rim_a = {"normal": .3, "focused": .45, "pressed": .45, "disabled": .14}[state]
        fill_a = {"normal": .07, "focused": .12, "pressed": .16, "disabled": .04}[state]
        off = (f'fill="#ffffff" fill-opacity="{fill_a}" stroke="#ffffff" stroke-opacity="{rim_a}"')
        on_a = .35 if state == "disabled" else 1
        on = f'fill="{css(ACC)}" fill-opacity="{on_a}"'
        mark = .4 if state == "disabled" else 1
        cell(f"checkbox-{state}", 16, f'<rect x=".5" y=".5" width="15" height="15" rx="4.5" {off}/>')
        cell(f"checkbox-checked-{state}", 16, f'<rect width="16" height="16" rx="5" {on}/>'
             + line("M4,8.5 L7,11 L12,5", mark, 1.8))
        cell(f"checkbox-tristate-{state}", 16, f'<rect width="16" height="16" rx="5" {on}/>'
             + line("M4.5,8 H11.5", mark, 1.8))
        cell(f"radio-{state}", 16, f'<circle cx="8" cy="8" r="7.5" {off}/>')
        cell(f"radio-checked-{state}", 16, f'<circle cx="8" cy="8" r="8" {on}/>'
             f'<circle cx="8" cy="8" r="3" fill="#ffffff" fill-opacity="{mark}"/>')
        knob = {"normal": "#ffffff", "focused": "#ffffff", "pressed": "#dcdce0", "disabled": "#737376"}[state]
        cell(f"slidercursor-{state}", 16, f'<circle cx="8" cy="8" r="7.5" fill="{knob}"/>')
    grip = "M10,2 L2,10 M10,6 L6,10"
    for state in ("normal", "focused"):
        cell(f"resize-grip-{state}", 12, line(grip, INK[state], 1.1))
    for state in ("normal", "focused", "pressed"):
        cell(f"splitter-grip-{state}", 12, line("M6,2 V10", INK[state], 1.4))
    cell("window-normal", 20, f'<rect width="20" height="20" fill="{WINDOW}"/>')
    return "".join(cells), y + step


def kv_svg():
    width = max(220, max(2 * R + 8 for R, _ in KV.values()))
    body, oy = [], 0
    for name, (R, states) in KV.items():
        for state in STATES:
            svg, height = kv_set(name, state, R, states[state], oy)
            body.append(svg)
            oy += height + 2
    # keyboard focus: rim only, on every widget
    svg, height = kv_set("focus", "", 6, S(WHITE, 0, ACC, .9), oy)
    body.append(svg)
    oy += height + 2
    glyphs, glyph_h = kv_glyphs(oy)
    body.append(glyphs)
    oy += glyph_h
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{oy}" '
            f'viewBox="0 0 {width} {oy}">{"".join(body)}</svg>')


def kv_config(translucent):
    lines = [
        "[%General]",
        "author=aryan",
        "comment=Dockyard: dark glass. Popups, menus and tooltips are glass; windows are "
        + ("glass too." if translucent else "solid."),
        "x11drag=all",
        "alt_mnemonic=true",
        "left_tabs=true",
        "attach_active_tab=false",
        "group_toolbar_buttons=false",
        "toolbar_item_spacing=2",
        "toolbar_interior_spacing=3",
        "spread_progressbar=true",
        "progressbar_thickness=6",
        "composite=true",
        # Kvantum draws these from menu-shadow elements, which this theme has none of.
        "menu_shadow_depth=0",
        "tooltip_shadow_depth=0",
        "menu_separator_height=6",
        "splitter_width=4",
        "scroll_width=8",
        "scroll_arrows=false",
        "scroll_min_extent=48",
        "slider_width=4",
        "slider_handle_width=16",
        "slider_handle_length=16",
        "check_size=16",
        "menubar_mouse_tracking=true",
        "toolbutton_style=0",
        "double_click=false",
        f"translucent_windows={'true' if translucent else 'false'}",
        f"reduce_window_opacity={'12' if translucent else '0'}",  # higher lets other windows' text show through bars
        "reduce_menu_opacity=0",
        "blurring=true",
        "popup_blurring=true",
        "menu_blur_radius=10",
        "tooltip_blur_radius=10",
        "vertical_spin_indicators=true",
        "inline_spin_indicators=true",
        "spin_button_width=28",
        "fill_rubberband=false",
        "merge_menubar_with_toolbar=false",
        "small_icon_size=16",
        "large_icon_size=32",
        "button_icon_size=16",
        "toolbar_icon_size=22",
        "combo_as_lineedit=true",
        "combo_menu=true",
        "hide_combo_checkboxes=true",
        "groupbox_top_label=true",
        "animate_states=true",
        "button_contents_shift=false",
        "layout_spacing=6",
        "layout_margin=9",
        "scrollbar_in_view=true",
        "transient_scrollbar=true",
        "transient_groove=true",
        "tooltip_delay=-1",
        "tree_branch_line=false",
        "dark_titlebar=true",
        "no_inactiveness=true",
        "respect_DE=true",
        "opaque=QMPlay2,kaffeine,kmplayer,subtitlecomposer,kdenlive,vlc,avidemux,kamoso,QtCreator,VirtualBox,dragon,digikam,virtualboxvm",
        "",
        "[GeneralColors]",
        f"window.color={WINDOW}",
        f"base.color={VIEW}",
        f"alt.base.color={VIEW_ALT}",
        f"button.color={BUTTON}",
        f"light.color={BUTTON_ALT}",
        f"mid.color={LINE}",
        "dark.color=#0e0e10",
        "highlight.color=#0071e3",
        f"text.color={APP_INK}",
        f"window.text.color={APP_INK}",
        f"button.text.color={APP_INK}",
        "disabled.text.color=#8e8e93",
        "tooltip.base.color=#16161a",
        f"tooltip.text.color={APP_INK}",
        "link.color=#64d2ff",
        "link.visited.color=#bf5af2",
        "highlight.text.color=#ffffff",
        "progress.indicator.text.color=#ffffff",
        "",
        "[Hacks]",
        "transparent_dolphin_view=true",
        "transparent_ktitle_label=true",
        "transparent_menutitle=true",
        f"blur_translucent={'true' if translucent else 'false'}",
        "respect_darkness=true",
        "normal_default_pushbutton=true",
        "iconless_pushbutton=false",
        "iconless_menu=false",
        "tint_on_mouseover=0",
        "no_selection_tint=false",
        "centered_forms=true",
        "kinetic_scrolling=false",
        "middle_click_scroll=false",
        "single_top_toolbar=true",
        "force_size_grip=true",
        "",
    ]
    for section, element, extra in KV_SECTIONS:
        R = 6 if element == "focus" else KV[element][0]
        lines += [
            f"[{section}]",
            "frame=true",
            f"frame.element={element}",
            f"frame.top={R}",
            f"frame.bottom={R}",
            f"frame.left={R}",
            f"frame.right={R}",
        ]
        if element != "focus":
            lines += ["interior=true", f"interior.element={element}"]
        lines += extra + TEXT + [""]
    for section, keys in KV_PLAIN:
        lines += [f"[{section}]"] + keys + TEXT + [""]
    return "\n".join(lines)


def color_scheme():
    head = ("[General]\nName=Dockyard\nColorScheme=Dockyard\n\n"
            "[KDE]\ncontrast=4\n\n"
            f"[WM]\nactiveBackground={rgb(HEADER)}\nactiveBlend={rgb(HEADER)}\nactiveForeground={rgb(APP_INK)}\n"
            f"inactiveBackground={rgb(HEADER_DIM)}\ninactiveBlend={rgb(HEADER_DIM)}\ninactiveForeground={rgb(APP_INK_2)}\n\n")
    dim = app("Header", HEADER_DIM, VIEW).replace("[Colors:Header]", "[Colors:Header][Inactive]")
    return head + app_colors + dim


def png(w, h, rgba):
    """Encode RGBA bytes as a PNG, with no image library."""
    rows = b"".join(b"\0" + rgba[y * w * 4:(y + 1) * w * 4] for y in range(h))
    chunk = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))


# Aurorae frame. KSvg sizes corners from the edge pieces, so left and right pieces are as
# wide as the corners and run under the client. Padding holds the shadow, as KWin expects.
PAD_L, PAD_T, PAD_B = 24, 16, 32   # left and right padding are equal
TITLE, CORNER = 34, 12
TOP_H = PAD_T + TITLE              # top pieces
SIDE_W = PAD_L + CORNER            # left and right pieces
BOTTOM_H = PAD_B + 1               # bottom pieces
DECO_W = 2 * SIDE_W + 8
DECO_H = TOP_H + 8 + BOTTOM_H
WIN_R = DECO_W - PAD_L             # window right edge in the piece canvas
WIN_B = TOP_H + 8 + 1              # window bottom edge


def shadow_alpha(x, y, peak, sigma):
    """Shadow opacity at canvas point x,y, for a large window at the padded position.

    Points map onto a 400 px window through its nearest corner, so the edge pieces stay
    uniform along their length and tile without seams. Inside the window it is 0."""
    if PAD_L <= x <= WIN_R and PAD_T <= y <= WIN_B:
        cx = PAD_L + CORNER if x < PAD_L + CORNER else WIN_R - CORNER if x > WIN_R - CORNER else x
        if y >= PAD_T + CORNER or math.hypot(x - cx, y - (PAD_T + CORNER)) <= CORNER:
            return 0
    size, dy, r = 400, 8, 6
    vx = x - PAD_L if x < DECO_W / 2 else size - (WIN_R - x)
    vy = y - PAD_T if y < TOP_H + 8 else size - (WIN_B - y)
    qx = abs(vx - size / 2) - size / 2 + r
    qy = abs(vy - dy - size / 2) - size / 2 + r
    d = math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r
    return peak if d <= 0 else peak * math.exp(-(d / sigma) ** 2)


def shadow_image(box, oy, peak, sigma):
    """An <image> of the shadow over `box` (x, y, w, h), at twice the pixel density."""
    x0, y0, w, h = box
    raw = bytearray()
    for py in range(h * 2):
        for px in range(w * 2):
            a = shadow_alpha(x0 + (px + .5) / 2, y0 + (py + .5) / 2, peak, sigma)
            raw += bytes((0, 0, 0, round(a * 255)))
    data = base64.b64encode(png(w * 2, h * 2, bytes(raw))).decode()
    return (f'<image x="{x0}" y="{y0 + oy}" width="{w}" height="{h}" '
            f'xlink:href="data:image/png;base64,{data}"/>')


def deco_set(prefix, oy, head, rim, peak, sigma):
    """The nine pieces of one Aurorae frame, drawn at y offset `oy`."""
    L, T, R_, B = PAD_L, PAD_T, WIN_R, WIN_B
    Y = TOP_H
    c = CORNER
    NONE = 'fill="none"'
    rect = lambda x, y, w, h, f: f'<rect x="{x}" y="{y + oy}" width="{w}" height="{h}" {f}/>'
    p = lambda x, y: f"{x},{y + oy}"
    fh = f'fill="{head}"'
    fr = f'fill="#ffffff" fill-opacity="{rim}"'
    fl = 'fill="#ffffff" fill-opacity="0.08"'
    edge = f'fill="{RIM_SOLID}"'
    boxes = {
        "topleft": (0, 0, SIDE_W, TOP_H), "top": (SIDE_W, 0, 8, TOP_H),
        "topright": (SIDE_W + 8, 0, SIDE_W, TOP_H), "left": (0, TOP_H, SIDE_W, 8),
        "right": (SIDE_W + 8, TOP_H, SIDE_W, 8), "bottomleft": (0, TOP_H + 8, SIDE_W, BOTTOM_H),
        "bottom": (SIDE_W, TOP_H + 8, 8, BOTTOM_H), "bottomright": (SIDE_W + 8, TOP_H + 8, SIDE_W, BOTTOM_H),
    }
    shapes = {
        "topleft": f'<path d="M{p(L, Y)} V{T + c + oy} A{c},{c} 0 0 1 {p(L + c, T)} V{Y + oy} Z" {fh}/>'
                   f'<path d="M{p(L, Y)} V{T + c + oy} A{c},{c} 0 0 1 {p(L + c, T)} V{T + 1 + oy} '
                   f'A{c-1},{c-1} 0 0 0 {p(L + 1, T + c)} V{Y + oy} Z" {fr}/>'
                   + rect(L + 1, Y - 1, c - 1, 1, fl),
        "top": rect(SIDE_W, T, 8, TITLE, fh) + rect(SIDE_W, T, 8, 1, fr) + rect(SIDE_W, Y - 1, 8, 1, fl),
        "topright": f'<path d="M{p(R_, Y)} V{T + c + oy} A{c},{c} 0 0 0 {p(R_ - c, T)} V{Y + oy} Z" {fh}/>'
                    f'<path d="M{p(R_, Y)} V{T + c + oy} A{c},{c} 0 0 0 {p(R_ - c, T)} V{T + 1 + oy} '
                    f'A{c-1},{c-1} 0 0 1 {p(R_ - 1, T + c)} V{Y + oy} Z" {fr}/>'
                    + rect(R_ - c, Y - 1, c - 1, 1, fl),
        "left": rect(L, Y, 1, 8, edge),
        "right": rect(R_ - 1, Y, 1, 8, edge),
        "bottomleft": rect(L, B - 1, c, 1, edge),
        "bottom": rect(SIDE_W, B - 1, 8, 1, edge),
        "bottomright": rect(R_ - c, B - 1, c, 1, edge),
    }
    out = []
    for part, box in boxes.items():
        out.append(f'<g id="{prefix}-{part}">{shadow_image(box, oy, peak, sigma)}{shapes[part]}</g>')
    out.append(f'<g id="{prefix}-center">{rect(SIDE_W, TOP_H, 8, 8, NONE)}</g>')
    return "".join(out)


def aurorae_svg():
    """Active and inactive frames, plus the plain bars a maximized window uses."""
    step = DECO_H + 4
    body = deco_set("decoration", 0, HEADER, .14, .38, 15)
    body += deco_set("decoration-inactive", step, HEADER_DIM, .08, .22, 11)
    bar = lambda pid, y, f: (f'<g id="{pid}"><rect x="0" y="{y}" width="{DECO_W}" height="{TITLE}" fill="{f}"/>'
                             f'<rect x="0" y="{y + TITLE - 1}" width="{DECO_W}" height="1" fill="#ffffff" fill-opacity="0.08"/></g>')
    body += bar("decoration-maximized-center", 2 * step, HEADER)
    body += bar("decoration-maximized-inactive-center", 2 * step + TITLE + 4, HEADER_DIM)
    body += '<rect id="decoration-hint-stretch-borders" width="1" height="1" fill="none"/>'
    body += '<rect id="decoration-inactive-hint-stretch-borders" width="1" height="1" fill="none"/>'
    h = 2 * step + 2 * TITLE + 4
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="{DECO_W}" height="{h}" viewBox="0 0 {DECO_W} {h}">{body}</svg>')


GLYPHS = {
    "close": "M12,8 L22,18 M22,8 L12,18",
    "minimize": "M12,13 L22,13",
    "maximize": "M12,8 H22 V18 H12 Z",
    "restore": "M11,10 H19 V18 H11 Z M14,10 V7 H22 V15 H19",
    "keepabove": "M12,15 L17,10 L22,15",
    "keepbelow": "M12,11 L17,16 L22,11",
    "alldesktops": "M12,8 H22 V18 H12 Z M15,11 H19 V15 H15 Z",
    "help": "M14.5,10.5 A2.5,2.5 0 1 1 18.5,12.5 C17.5,13.2 17,13.8 17,15 M17,17.6 V18.2",
    "shade": "M12,9 H22 M12,14 L17,18 L22,14",
    "appmenu": "M12,9 H22 M12,13 H22 M12,17 H22",
}


def aurorae_button(glyph):
    """Every state KWin's AuroraeButton reads. Each is a <prefix>-center group holding the
    background and the glyph, on a full size box so KSvg does not stretch the drawing."""
    close = glyph == "close"
    hover = f'fill="{css(NEG)}"' if close else 'fill="#ffffff" fill-opacity="0.10"'
    press = 'fill="#d9332a"' if close else 'fill="#ffffff" fill-opacity="0.16"'
    states = {
        "active": (None, .7), "inactive": (None, .35),
        "hover": (hover, 1), "hover-inactive": (hover, .9),
        "pressed": (press, 1), "pressed-inactive": (press, .9),
        "deactivated": (None, .25), "deactivated-inactive": (None, .15),
    }
    d = GLYPHS[glyph]
    box = '<rect width="34" height="34" fill="#ffffff" fill-opacity="0"/>'
    groups = ""
    for prefix, (bg, a) in states.items():
        # The button fills the title height and sits in the window corner, so the close
        # hover reaches the top right edge. Square, because KWin gives buttons no maximized
        # state, so a rounded corner would show when the window is maximized.
        if not bg:
            back = ""
        elif close:
            back = f'<rect width="34" height="34" {bg}/>'
        else:
            back = f'<rect x="2" y="5" width="30" height="24" rx="6" {bg}/>'
        icon = (f'<path d="{d}" fill="none" stroke="#ffffff" stroke-opacity="{a}" stroke-width="1.2" '
                'stroke-linecap="round" stroke-linejoin="round"/>')
        groups += f'<g id="{prefix}-center">{box}{back}<g transform="translate(0,4)">{icon}</g></g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="34" height="34" viewBox="0 0 34 34">{groups}</svg>'


def aurorae_rc():
    return f"""[General]
ActiveTextColor={rgb(APP_INK)},255
InactiveTextColor={rgb(APP_INK_2)},255
TitleAlignment=Left
TitleVerticalAlignment=Center
Animation=120
Shadow=true

[Layout]
BorderLeft=1
BorderRight=1
BorderBottom=1
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=6
TitleEdgeRight=0
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={TITLE}
ButtonWidth=34
ButtonWidthClose=34
ButtonWidthMaximizeRestore=34
ButtonWidthMinimize=34
ButtonWidthKeepabove=34
ButtonWidthKeepbelow=34
ButtonWidthHelp=34
ButtonWidthAlldesktops=34
ButtonWidthShade=34
ButtonWidthAppMenu=34
ButtonHeight=34
ButtonSpacing=2
ButtonMarginTop=0
ButtonMarginTopMaximized=0
ExplicitButtonSpacer=6
PaddingTop={PAD_T}
PaddingBottom={PAD_B}
PaddingRight={PAD_L}
PaddingLeft={PAD_L}
TitleHeightMaximized={TITLE}
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=6
TitleEdgeRightMaximized=0
"""


def look_and_feel_defaults():
    return """[kdeglobals][General]
ColorScheme=Dockyard

[kdeglobals][KDE]
widgetStyle=kvantum

[kwinrc][org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__Dockyard

[plasmarc][Theme]
name=glass
"""


SPLASH = """import QtQuick

// Dockyard boot splash. ksplashqml sets stage from 1 to 6 as the session starts.
Rectangle {
    id: root
    property int stage: 0
    color: "#16161a"

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Dockyard"
            color: "#ffffff"
            font.pixelSize: 24
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: 160
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
                width: parent.width * Math.min(root.stage, 6) / 6
                height: parent.height
                radius: 2
                color: "#0A84FF"
                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }
}
"""


if NAME == "glass":
    put("color-schemes/Dockyard.colors", color_scheme())

    svg = kv_svg()
    for folder, translucent in (("Dockyard", False), ("DockyardGlass", True)):
        put(f"kvantum/{folder}/{folder}.kvconfig", kv_config(translucent))
        put(f"kvantum/{folder}/{folder}.svg", svg)

    put("aurorae/Dockyard/decoration.svg", aurorae_svg())
    put("aurorae/Dockyard/Dockyardrc", aurorae_rc())
    put("aurorae/Dockyard/metadata.json", json.dumps({
        "KPlugin": {
            "Authors": [{"Email": "", "Name": "aryan"}],
            "Category": "",
            "Description": "Dockyard: dark glass titlebar with monochrome buttons.",
            "EnabledByDefault": True,
            "Id": "Dockyard",
            "License": "GPL-2.0+",
            "Name": "Dockyard",
            "Version": "1.1",
        },
    }, indent=4) + "\n")
    put("aurorae/Dockyard/metadata.desktop", """[Desktop Entry]
Name=Dockyard
Comment=Dark glass titlebar with monochrome buttons.
X-KDE-PluginInfo-Author=aryan
X-KDE-PluginInfo-Name=Dockyard
X-KDE-PluginInfo-Version=1.1
X-KDE-PluginInfo-License=GPL-2.0+
X-KDE-PluginInfo-EnabledByDefault=true
""")
    for name in GLYPHS:
        put(f"aurorae/Dockyard/{name}.svg", aurorae_button(name))

    put("look-and-feel/dev.aryan.dockyard/metadata.json", json.dumps({
        "KPackageStructure": "Plasma/LookAndFeel",
        "KPlugin": {
            "Authors": [{"Name": "aryan"}],
            "Description": "Dockyard dark glass: color scheme, Kvantum, Aurorae and the glass Plasma theme.",
            "Id": "dev.aryan.dockyard",
            "License": "GPL-2.0+",
            "Name": "Dockyard",
            "Version": "1.1",
        },
    }, indent=4) + "\n")
    put("look-and-feel/dev.aryan.dockyard/contents/defaults", look_and_feel_defaults())
    put("look-and-feel/dev.aryan.dockyard/contents/splash/Splash.qml", SPLASH)
