#!/bin/sh
# Builds dockyard.plasmoid, the package to upload to store.kde.org.
set -e
cd "$(dirname "$0")/package"
rm -f ../dockyard.plasmoid
python3 - <<'PY'
import os, zipfile
with zipfile.ZipFile("../dockyard.plasmoid", "w", zipfile.ZIP_DEFLATED) as z:
    z.write("metadata.json")
    for root, dirs, files in os.walk("contents"):
        for f in sorted(files):
            if not f.endswith((".qmlc", "~")):
                z.write(os.path.join(root, f))
PY
echo "built $(cd .. && pwd)/dockyard.plasmoid"
