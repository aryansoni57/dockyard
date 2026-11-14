#!/usr/bin/env python3
"""Check WCAG contrast of every text color on every surface in a KDE color scheme.

Usage: theme/contrast.py [file.colors ...]   (default: the Dockyard Day files)

Each [Colors:*] group is checked: every Foreground* key against BackgroundNormal and
BackgroundAlternate, plus the [WM] title colors. Text needs 4.5:1 (AA). DecorationFocus and
DecorationHover are not text: they need 3:1 against the group background (WCAG 1.4.11).
For the translucent Plasma glass, ink is also checked over the glass composited on black
and on white, the worst cases behind a frosted surface. Exits 1 when anything fails."""
import configparser, os, sys

BASE = os.path.dirname(os.path.abspath(__file__))


def lum(c):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = c
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def parse(v):
    return tuple(int(x) for x in v.split(",")[:3])


def over(fg, a, bg):
    return tuple(round(f * a + b * (1 - a)) for f, b in zip(fg, bg))


def check_scheme(path):
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    cp.optionxform = str
    cp.read(path)
    fails, rows = 0, []
    for sec in cp.sections():
        if not sec.startswith("Colors:"):
            continue
        g = cp[sec]
        for bgk in ("BackgroundNormal", "BackgroundAlternate"):
            if bgk not in g:
                continue
            bg = parse(g[bgk])
            for k, v in g.items():
                if k.startswith("Foreground"):
                    need = 4.5
                elif k.startswith("Decoration"):
                    need = 3.0
                else:
                    continue
                r = ratio(parse(v), bg)
                ok = r >= need
                fails += not ok
                rows.append((ok, f"{sec:28} {k:20} on {bgk:19} {r:5.2f}  (need {need})"))
    if cp.has_section("WM"):
        w = cp["WM"]
        for state in ("active", "inactive"):
            r = ratio(parse(w[state + "Foreground"]), parse(w[state + "Background"]))
            ok = r >= 4.5
            fails += not ok
            rows.append((ok, f"{'WM':28} {state + 'Foreground':20} on {state + 'Background':19} {r:5.2f}  (need 4.5)"))
    return fails, rows


def main():
    files = sys.argv[1:] or [os.path.join(BASE, "color-schemes/DockyardDay.colors"),
                             os.path.join(BASE, "glass-day/colors")]
    total = 0
    for f in files:
        fails, rows = check_scheme(f)
        print(f"== {os.path.relpath(f, BASE)}: {len(rows) - fails}/{len(rows)} pass")
        for ok, line in rows:
            print(("  ok   " if ok else "  FAIL ") + line)
        total += fails

    # Frosted Plasma glass and Kvantum glass menus: ink over the glass on the worst ground.
    if not sys.argv[1:]:
        ink, app_ink2, plasma_ink2 = (28, 28, 30), (92, 94, 102), (75, 77, 85)
        glass = (248, 248, 251)
        print("== translucent surfaces, ink on glass over black / white ground")
        for what, a, ink2 in (("Plasma panel 0.78", .78, plasma_ink2), ("Plasma dialog 0.82", .82, plasma_ink2),
                              ("Plasma tooltip 0.88", .88, plasma_ink2), ("Kvantum menu 0.88", .88, app_ink2),
                              ("Kvantum tooltip 0.90", .90, app_ink2)):
            for name, fg in (("ink", ink), ("ink-2", ink2)):
                worst = min(ratio(fg, over(glass, a, (0, 0, 0))), ratio(fg, over(glass, a, (255, 255, 255))))
                need = 4.5
                ok = worst >= need
                total += not ok
                print(("  ok   " if ok else "  FAIL ") + f"{what:22} {name:6} worst {worst:5.2f}  (need {need})")
        sel, white = (0, 100, 214), (255, 255, 255)
        r = ratio(white, sel)
        total += r < 4.5
        print(("  ok   " if r >= 4.5 else "  FAIL ") + f"{'white on selection':29} {r:5.2f}  (need 4.5)")
        red = (224, 36, 46)
        r = ratio(white, red)
        total += r < 4.5
        print(("  ok   " if r >= 4.5 else "  FAIL ") + f"{'white close glyph on red':29} {r:5.2f}  (need 4.5)")
    print("FAILURES:", total)
    sys.exit(1 if total else 0)


main()
