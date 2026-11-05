# Writes icons.js: every SVG in assets/ as a data URI, keyed by file name.
import glob, json, os, urllib.parse

here = os.path.dirname(os.path.abspath(__file__))
icons = {}
for f in sorted(glob.glob(os.path.join(here, "assets", "*.svg"))):
    with open(f) as fh:
        icons[os.path.basename(f)[:-4]] = "data:image/svg+xml," + urllib.parse.quote(fh.read())
with open(os.path.join(here, "icons.js"), "w") as fh:
    fh.write("window.ICONS=" + json.dumps(icons) + ";")
