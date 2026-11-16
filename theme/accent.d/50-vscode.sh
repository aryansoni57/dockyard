#!/bin/sh
# VS Code: a few accent colours in workbench.colorCustomizations (focus ring, links, buttons, progress,
# badges). Only these keys are touched. A settings.json with comments is skipped, not rewritten.
python3 - "$ACCENT" <<'PY'
import json, os, sys
accent = sys.argv[1]
f = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "Code", "User", "settings.json")
if not os.path.exists(f):
    sys.exit(0)
try:
    data = json.load(open(f))
except Exception:
    sys.exit(0)          # JSON with comments: leave it alone
def lin(v): return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
def lum(c): return 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2])
rgb = tuple(int(accent[i:i + 2], 16) / 255 for i in (1, 3, 5))
fill = rgb
for i in range(41):                       # darken until white text on it is AA
    fill = tuple(c * (1 - i / 40) for c in rgb)
    if 1.05 / (lum(fill) + 0.05) >= 4.5:
        break
fill = "#%02x%02x%02x" % tuple(round(v * 255) for v in fill)
cc = data.setdefault("workbench.colorCustomizations", {})
for k in ("focusBorder", "textLink.foreground", "progressBar.background", "inputOption.activeBorder"):
    cc[k] = accent
for k in ("button.background", "activityBarBadge.background"):
    cc[k] = fill
json.dump(data, open(f, "w"), indent=4, ensure_ascii=False)
open(f, "a").write("\n")
PY
