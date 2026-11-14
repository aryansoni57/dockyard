#!/usr/bin/env bash
# Install the Dockyard set (color scheme, Kvantum, Aurorae, look-and-feel), then apply it.
# The Day set (DockyardDay, the light counterpart the dock's Day and night look switches
# to) is installed beside it; --day applies the Day set instead of the dark one.
# The first run saves your current choices to ~/.local/state/dockyard/baseline. Later runs
# keep that baseline, so theme/restore-global.sh always returns to the pre-Dockyard setup.
# Usage: theme/install-global.sh [--no-apply] [--day]   (--no-apply only copies the files)
set -euo pipefail
cd "$(dirname "$0")"

apply=1
day=0
for a in "$@"; do
    case "$a" in
        --no-apply) apply=0 ;;
        --day) day=1 ;;
        *) echo "unknown option: $a" >&2; exit 1 ;;
    esac
done

data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
baseline="${XDG_STATE_HOME:-$HOME/.local/state}/dockyard/baseline"

read_key() { kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null || true; }

save_baseline() {
    lnf=$(read_key kdeglobals KDE LookAndFeelPackage)
    if [ "$lnf" = dev.aryan.dockyard ] || [ "$lnf" = dev.aryan.dockyard.day ]; then
        echo "Dockyard is already active and no baseline exists, so nothing was saved" >&2
        return
    fi
    mkdir -p "$baseline"
    {
        printf 'style=%q\n' "$(read_key kdeglobals KDE widgetStyle)"
        printf 'scheme=%q\n' "$(read_key kdeglobals General ColorScheme)"
        printf 'lnf=%q\n' "$lnf"
        printf 'icons=%q\n' "$(read_key kdeglobals Icons Theme)"
        printf 'cursor=%q\n' "$(read_key kcminputrc Mouse cursorTheme)"
        printf 'deco_lib=%q\n' "$(read_key kwinrc org.kde.kdecoration2 library)"
        printf 'deco_theme=%q\n' "$(read_key kwinrc org.kde.kdecoration2 theme)"
        printf 'plasma_theme=%q\n' "$(read_key plasmarc Theme name)"
        printf 'kvantum=%q\n' "$(read_key Kvantum/kvantum.kvconfig General theme)"
    } > "$baseline/settings"
    # plasma-apply-lookandfeel rewrites these, so the restore copies them back
    if [ -d "$config/kdedefaults" ]; then
        cp -a "$config/kdedefaults" "$baseline/kdedefaults"
    fi
    echo "Saved current choices: $baseline"
}

[ -f "$baseline/settings" ] || save_baseline

# Files: the dark set and the Day set
for kv in Dockyard DockyardGlass DockyardDay DockyardDayGlass; do
    mkdir -p "$config/Kvantum/$kv"
    cp kvantum/$kv/* "$config/Kvantum/$kv/"
done
mkdir -p "$data/color-schemes"
cp color-schemes/Dockyard.colors color-schemes/DockyardDay.colors "$data/color-schemes/"
mkdir -p "$data/aurorae/themes"
for deco in Dockyard DockyardDay; do
    rm -rf "$data/aurorae/themes/$deco"
    cp -r aurorae/$deco "$data/aurorae/themes/"
done
mkdir -p "$data/plasma/look-and-feel"
for lnf in dev.aryan.dockyard dev.aryan.dockyard.day; do
    rm -rf "$data/plasma/look-and-feel/$lnf"
    cp -r look-and-feel/$lnf "$data/plasma/look-and-feel/"
done
# The Day Plasma themes, so the look-and-feel and day-night.sh find them. install-all.sh
# installs the dark glass themes with the plasmoid.
mkdir -p "$data/plasma/desktoptheme"
for t in glass-day glass-day-opaque; do
    rm -rf "$data/plasma/desktoptheme/$t"
    cp -r "$t" "$data/plasma/desktoptheme/$t"
done
echo "Installed Dockyard and Dockyard Day files"

if [ "$apply" = 1 ] && [ "$day" = 1 ]; then
    # Same steps as below, with the Day set.
    plasma-apply-lookandfeel -a dev.aryan.dockyard.day
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
    kvantummanager --set DockyardDay
    plasma-apply-colorscheme DockyardDay
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__DockyardDay
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    echo "Applied Dockyard Day. Restart open Qt apps to pick up the style. Undo with: $PWD/restore-global.sh"
elif [ "$apply" = 1 ]; then
    # Default app style: solid windows with glass menus and tooltips (Dockyard, not DockyardGlass).
    # A look-and-feel cannot pick a Kvantum theme, so this script is the supported way to apply.
    plasma-apply-lookandfeel -a dev.aryan.dockyard
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
    kvantummanager --set Dockyard
    plasma-apply-colorscheme Dockyard
    # KWin keeps a loaded Aurorae theme until the decoration changes, so step through Breeze.
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Dockyard
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    echo "Applied Dockyard. Restart open Qt apps to pick up the style. Undo with: $PWD/restore-global.sh"
fi
