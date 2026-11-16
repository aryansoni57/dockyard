#!/usr/bin/env python3
"""Set the accent in every installed Dockyard Plasma theme's `colors` file.

Plasma themes ship their own palette, which overrides the colour scheme for the shell (OSD slider,
panel, widgets). Usage: apply-accent.py '#rrggbb'
"""
import glob, os, re, sys

hexc = sys.argv[1].lstrip("#")
rgb = ",".join(str(int(hexc[i:i + 2], 16)) for i in (0, 2, 4))
root = os.path.expanduser("~/.local/share/plasma/desktoptheme")
keys = ("DecorationFocus", "DecorationHover", "ForegroundActive")
for path in glob.glob(os.path.join(root, "glass*", "colors")):
    out, section = [], ""
    for line in open(path).read().split("\n"):
        m = re.match(r"\[(.+)\]", line)
        if m:
            section = m.group(1)
        k = line.split("=", 1)[0]
        if k in keys or (section == "Colors:Selection" and k == "BackgroundNormal"):
            line = k + "=" + rgb
        out.append(line)
    open(path, "w").write("\n".join(out))
