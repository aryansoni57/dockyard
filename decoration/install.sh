#!/usr/bin/env bash
# Builds Dockyard Glass and installs it for the current user only.
#
#   ./install.sh              build + install plugin + Plasma env script
#   ./install.sh --activate   also select it in kwinrc (takes effect at next login)
#   ./install.sh --uninstall  remove the plugin and env script
#
# KWin finds decorations in <Qt plugin path>/org.kde.kdecoration3. The user
# folder ~/.local/lib/qt6/plugins is NOT searched by default, so this script
# adds it to QT_PLUGIN_PATH through ~/.config/plasma-workspace/env/, which
# startplasma runs before KWin starts. That needs a log out and back in.
# This script never restarts or reconfigures the running KWin.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$HERE/build"
PLUGIN_ROOT="$HOME/.local/lib/qt6/plugins"
PLUGIN_DIR="$PLUGIN_ROOT/org.kde.kdecoration3"
ENV_SCRIPT="$HOME/.config/plasma-workspace/env/dockyard-glass.sh"
NINJA=/usr/bin/ninja

if [[ "${1:-}" == "--uninstall" ]]; then
    rm -f "$PLUGIN_DIR/org.dockyard.glass.so" "$ENV_SCRIPT"
    echo "Removed. If kwinrc still selects org.dockyard.glass, switch the decoration back first:"
    echo "  System Settings > Colors & Themes > Window Decorations"
    exit 0
fi

cmake -S "$HERE" -B "$BUILD" -G Ninja -DCMAKE_MAKE_PROGRAM="$NINJA" -DCMAKE_BUILD_TYPE=Release
"$NINJA" -C "$BUILD"

mkdir -p "$PLUGIN_DIR"
install -m 0755 "$BUILD/plugins/org.kde.kdecoration3/org.dockyard.glass.so" "$PLUGIN_DIR/"
echo "Installed $PLUGIN_DIR/org.dockyard.glass.so"

mkdir -p "$(dirname "$ENV_SCRIPT")"
cat > "$ENV_SCRIPT" <<'EOF'
# Added by Dockyard Glass: let KWin and System Settings find user-installed
# Qt plugins (window decorations in ~/.local/lib/qt6/plugins/org.kde.kdecoration3).
case ":${QT_PLUGIN_PATH:-}:" in
    *":$HOME/.local/lib/qt6/plugins:"*) ;;
    *) export QT_PLUGIN_PATH="$HOME/.local/lib/qt6/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}" ;;
esac
EOF
echo "Wrote $ENV_SCRIPT"

# Default settings file (only if the user has none yet).
CONF="$HOME/.config/dockyardglassrc"
if [[ ! -f "$CONF" ]]; then
    cat > "$CONF" <<'EOF'
[General]
TitleOpacityDark=0.62
TitleOpacityLight=0.70
InactiveOpacityScale=0.92
TitleHeight=34
ButtonWidth=34
CornerRadius=10
BlurBorders=true
TitleHighlight=true
TitleHairline=true
ShadowSize=32
ShadowStrength=1.0
HoverDuration=120
EOF
    echo "Wrote $CONF"
fi

if [[ "${1:-}" == "--activate" ]]; then
    # Written to the file only; the running KWin is not told to reload.
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.dockyard.glass
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme ""
    echo "kwinrc now selects org.dockyard.glass (applies at next login)."
fi

cat <<'EOF'

Next steps:
  1. Save your work, log out and log back in (so QT_PLUGIN_PATH reaches KWin).
  2. System Settings > Colors & Themes > Window Decorations > Dockyard Glass > Apply
     (skip if you used --activate).
To go back: pick "Dockyard" (or "Dockyard Day") in the same page.
EOF
