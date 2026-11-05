#!/usr/bin/env bash
# Install the Dockyard set (color scheme, Kvantum, Aurorae, look-and-feel), then apply it.
# The first run saves your current choices to ~/.local/state/dockyard/baseline. Later runs
# keep that baseline, so theme/restore-global.sh always returns to the pre-Dockyard setup.
# Usage: theme/install-global.sh [--no-apply]   (--no-apply only copies the files)
set -euo pipefail
cd "$(dirname "$0")"

apply=1
for a in "$@"; do
    case "$a" in
        --no-apply) apply=0 ;;
        *) echo "unknown option: $a" >&2; exit 1 ;;
    esac
done

data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
baseline="${XDG_STATE_HOME:-$HOME/.local/state}/dockyard/baseline"

read_key() { kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null || true; }

save_baseline() {
    lnf=$(read_key kdeglobals KDE LookAndFeelPackage)
    if [ "$lnf" = dev.aryan.dockyard ]; then
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

# Files
mkdir -p "$config/Kvantum/Dockyard" "$config/Kvantum/DockyardGlass"
cp kvantum/Dockyard/* "$config/Kvantum/Dockyard/"
cp kvantum/DockyardGlass/* "$config/Kvantum/DockyardGlass/"
mkdir -p "$data/color-schemes"
cp color-schemes/Dockyard.colors "$data/color-schemes/"
rm -rf "$data/aurorae/themes/Dockyard"
mkdir -p "$data/aurorae/themes"
cp -r aurorae/Dockyard "$data/aurorae/themes/"
rm -rf "$data/plasma/look-and-feel/dev.aryan.dockyard"
mkdir -p "$data/plasma/look-and-feel"
cp -r look-and-feel/dev.aryan.dockyard "$data/plasma/look-and-feel/"
echo "Installed Dockyard files"

if [ "$apply" = 1 ]; then
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
