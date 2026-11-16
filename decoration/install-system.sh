#!/usr/bin/env bash
# Alternative to install.sh: installs the plugin system-wide into the default
# Qt plugin folder, so no QT_PLUGIN_PATH change is needed. Uses sudo for the
# copy only. Run it yourself; it does not restart KWin.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$HERE/build"
DEST=/usr/lib/qt6/plugins/org.kde.kdecoration3

if [[ "${1:-}" == "--uninstall" ]]; then
    sudo rm -f "$DEST/org.dockyard.glass.so"
    echo "Removed $DEST/org.dockyard.glass.so"
    exit 0
fi

cmake -S "$HERE" -B "$BUILD" -G Ninja -DCMAKE_MAKE_PROGRAM=/usr/bin/ninja -DCMAKE_BUILD_TYPE=Release
/usr/bin/ninja -C "$BUILD"
sudo install -m 0755 "$BUILD/plugins/org.kde.kdecoration3/org.dockyard.glass.so" "$DEST/"
echo "Installed $DEST/org.dockyard.glass.so"
echo "Pick it in System Settings > Colors & Themes > Window Decorations (or log out and in first)."
