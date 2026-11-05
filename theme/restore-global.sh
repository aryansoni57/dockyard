#!/usr/bin/env bash
# Put back the choices install-global.sh saved before Dockyard was first applied. It does
# not run plasma-apply-lookandfeel, which would also reset icons, cursor and wallpaper.
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}"
baseline="${XDG_STATE_HOME:-$HOME/.local/state}/dockyard/baseline"

if [ ! -f "$baseline/settings" ]; then
    echo "no saved choices in $baseline" >&2
    exit 1
fi
# shellcheck source=/dev/null
. "$baseline/settings"

if [ -d "$baseline/kdedefaults" ]; then
    rm -rf "$config/kdedefaults"
    cp -a "$baseline/kdedefaults" "$config/kdedefaults"
fi
kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "$lnf"
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "$style"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "$deco_lib"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "$deco_theme"
kvantummanager --set "$kvantum"
plasma-apply-colorscheme "$scheme"
plasma-apply-desktoptheme "$plasma_theme"
/usr/lib/plasma-changeicons "$icons" || true
plasma-apply-cursortheme "$cursor" || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# The next install-global.sh takes a fresh baseline.
mv "$baseline" "$baseline.restored-$(date +%Y%m%d-%H%M%S)"
systemctl --user restart plasma-plasmashell
echo "Restored. Restart open Qt apps to pick up the style."
