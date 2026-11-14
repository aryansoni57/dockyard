#!/bin/sh
# Apply a Plasma color scheme, unless it is the current one already.
# For the Dockyard schemes (Dockyard for night, DockyardDay for day) the rest of the set
# follows: the Plasma theme (glass / glass-day, keeping the opaque, frosted or islands
# variant), the Kvantum theme and the Aurorae decoration. Each of those only changes when
# a Dockyard one is already active, so another theme is never replaced.
# Usage: day-night.sh <scheme name>   (names from: plasma-apply-colorscheme --list-schemes)
scheme="$1"
[ -n "$scheme" ] || exit 1
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

case "$scheme" in
    DockyardDay) tone=day; family=glass-day; kvset=DockyardDay ;;
    Dockyard) tone=night; family=glass; kvset=Dockyard ;;
    *) tone= ;;
esac

# DockyardDay is the default day scheme, but only theme/install-global.sh installs it.
if [ "$tone" = day ] && [ ! -f "$data/color-schemes/DockyardDay.colors" ] \
    && [ ! -f /usr/share/color-schemes/DockyardDay.colors ]; then
    scheme=BreezeLight
    tone=
fi

cur=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
if [ -z "$tone" ]; then
    [ "$cur" = "$scheme" ] && exit 0
    exec plasma-apply-colorscheme "$scheme"
fi
[ "$cur" = "$scheme" ] || plasma-apply-colorscheme "$scheme"

has_theme() {
    [ -d "$data/plasma/desktoptheme/$1" ] || [ -d "/usr/share/plasma/desktoptheme/$1" ]
}

# Plasma theme: same variant, other set.
here="$(dirname "$0")"
pt=$(kreadconfig6 --file plasmarc --group Theme --key name)
case "$pt" in
    glass|glass-day) want="$family" ;;
    glass-opaque|glass-day-opaque) want="$family-opaque" ;;
    glass-islands|glass-day-islands) want="$family-islands" ;;
    *) want= ;;
esac
if [ -n "$want" ] && [ "$pt" != "$want" ]; then
    case "$want" in
        *-islands) has_theme "$family" && DOCKYARD_TONE="$tone" sh "$here/layout-theme.sh" islands ;;
        *) has_theme "$want" && plasma-apply-desktoptheme "$want" ;;
    esac
fi

# Kvantum: same solid or translucent windows, other set.
kv=$(kreadconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme)
case "$kv" in
    Dockyard|DockyardDay) kvwant="$kvset" ;;
    DockyardGlass|DockyardDayGlass) kvwant="${kvset}Glass" ;;
    *) kvwant= ;;
esac
if [ -n "$kvwant" ] && [ "$kv" != "$kvwant" ] && [ -d "$config/Kvantum/$kvwant" ]; then
    kvantummanager --set "$kvwant"
fi

# Aurorae window decoration.
deco=$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme)
case "$deco" in
    __aurorae__svg__Dockyard|__aurorae__svg__DockyardDay)
        dwant="__aurorae__svg__$kvset"
        if [ "$deco" != "$dwant" ] && { [ -d "$data/aurorae/themes/$kvset" ] || [ -d "/usr/share/aurorae/themes/$kvset" ]; }; then
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "$dwant"
            qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
        fi ;;
esac
exit 0
