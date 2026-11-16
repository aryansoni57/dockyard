#!/usr/bin/env bash
# Dockyard full setup: dock, glass themes, global look, settings app, and optional extras.
#
#   ./setup.sh                 dock + glass Plasma themes + Dockyard look (night, frosted glass) + settings app
#   ./setup.sh --day           apply the Day look instead of the night one
#   ./setup.sh --check         only check dependencies, change nothing
#
# Options:
#   --no-apply      copy theme files but do not switch your desktop to them
#   --no-settings   skip the Settings app (needs cmake, ninja, g++ and the KDE dev packages)
#   --tela          install the Tela icon theme (the Dockyard looks use it) from github.com/vinceliuice/Tela-icon-theme
#   --decoration    also install the Dockyard Glass window decoration (blurred title bars; log out and in after)
#   --login         also install the login wallpaper and boot splash (needs sudo); the greeter has its own build
#   --no-restart    do not restart plasmashell at the end
#
# Your current theme choices are saved first (theme/restore-global.sh puts them back).
set -euo pipefail
cd "$(dirname "$0")"

day=0 apply=1 settings=1 tela=0 deco=0 login=0 restart=1 check=0
for a in "$@"; do
    case "$a" in
        --day) day=1 ;;
        --no-apply) apply=0 ;;
        --no-settings) settings=0 ;;
        --tela) tela=1 ;;
        --decoration) deco=1 ;;
        --login) login=1 ;;
        --no-restart) restart=0 ;;
        --check) check=1 ;;
        -h|--help) sed -n 2,20p "$0"; exit 0 ;;
        *) echo "unknown option: $a (see --help)" >&2; exit 1 ;;
    esac
done

# ---- Dependencies ----
missing=0
need() { # command, what it is for, Arch package
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "  missing: $1  ($2; Arch package: $3)"; missing=1
    fi
}
echo "Checking dependencies"
need kpackagetool6 "installs the dock" plasma-sdk-or-kpackage
need plasmashell "KDE Plasma 6" plasma-desktop
need kwriteconfig6 "writes settings" kconfig
need plasma-apply-colorscheme "applies the colour scheme" plasma-workspace
need plasma-apply-lookandfeel "applies the global look" plasma-workspace
need plasma-apply-desktoptheme "applies the glass Plasma theme" plasma-workspace
need lookandfeeltool "switches looks" plasma-workspace
need kvantummanager "the Dockyard app style (Kvantum)" kvantum
if [ "$settings" = 1 ]; then
    need cmake "builds the Settings app plugin" cmake
    need ninja "builds the Settings app plugin" ninja
    need c++ "builds the Settings app plugin" gcc
    need qml6 "runs the Settings app" qt6-declarative
    ls /usr/lib/cmake/KF6KCMUtils >/dev/null 2>&1 || { echo "  missing: KF6 KCMUtils dev files (kcmutils)"; missing=1; }
    ls /usr/lib/cmake/KF6ColorScheme >/dev/null 2>&1 || { echo "  missing: KF6 ColorScheme dev files (kcolorscheme)"; missing=1; }
    ls /usr/lib/cmake/KF6WindowSystem >/dev/null 2>&1 || { echo "  missing: KF6 WindowSystem dev files (kwindowsystem)"; missing=1; }
fi
if [ "$deco" = 1 ]; then
    ls /usr/lib/cmake/KDecoration3 >/dev/null 2>&1 || { echo "  missing: KDecoration3 dev files (kdecoration)"; missing=1; }
fi
icons_ok=0
for d in "$HOME/.local/share/icons" /usr/share/icons; do
    [ -d "$d/Tela-dark" ] && [ -d "$d/Tela" ] && icons_ok=1
done
if [ "$icons_ok" = 0 ] && [ "$tela" = 0 ]; then
    echo "  note: Tela icons not found. The Dockyard looks ask for Tela and Tela-dark; without them you get the default icons."
    echo "        Run with --tela to install them, or install the 'tela-icon-theme' package from your distribution or AUR."
fi
if [ "$missing" = 1 ]; then
    echo "Install the missing pieces above and run again." >&2
    exit 1
fi
echo "Dependencies OK"
[ "$check" = 1 ] && exit 0

# ---- Tela icons (optional) ----
if [ "$tela" = 1 ] && [ "$icons_ok" = 0 ]; then
    tmp=$(mktemp -d)
    git clone --depth 1 https://github.com/vinceliuice/Tela-icon-theme "$tmp/tela"
    # Per user, standard and dark variants.
    "$tmp/tela/install.sh" -d "$HOME/.local/share/icons" standard
    rm -rf "$tmp"
fi

# ---- Dock, glass themes, global look ----
args=(--no-restart)
if [ "$apply" = 1 ] && [ "$day" = 0 ]; then
    args+=(--apply-theme --apply-global)
fi
./install-all.sh "${args[@]}"
if [ "$apply" = 0 ]; then
    theme/install-global.sh --no-apply
elif [ "$day" = 1 ]; then
    theme/install-global.sh --day
fi

# ---- Settings app ----
if [ "$settings" = 1 ]; then
    settings/install.sh
fi

# ---- Optional extras ----
if [ "$deco" = 1 ]; then
    decoration/install.sh --activate
    echo "Dockyard Glass window decoration installed. Log out and in to load it."
fi
if [ "$login" = 1 ]; then
    login/install.sh
    echo "The login greeter has its own build: login/greeter/build.sh and install-greeter.sh."
fi

if [ "$restart" = 1 ]; then
    systemctl --user restart plasma-plasmashell
fi
echo "Done. Restart open Qt apps to pick up the app style. Undo the look with theme/restore-global.sh."
