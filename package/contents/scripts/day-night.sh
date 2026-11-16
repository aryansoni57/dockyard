#!/bin/sh
# Apply a Plasma color scheme, unless it is the current one already.
# For the Dockyard schemes (Dockyard for night, DockyardDay for day) the rest of the set
# follows: the Plasma theme (glass / glass-day, keeping the opaque, frosted or islands
# variant), the Kvantum theme and the Aurorae decoration. Each of those only changes when
# a Dockyard one is already active, so another theme is never replaced.
# BreezeLight and BreezeDark work as a pair too: the Plasma theme becomes breeze-light /
# breeze-dark, the app style Breeze and the decoration Breeze. What was swapped is noted in
# $XDG_STATE_HOME/dockyard/breeze-swap, and only that is put back when a Dockyard scheme
# returns, so a Breeze choice the user made themselves is never overwritten.
# Usage: day-night.sh <scheme name>   (names from: plasma-apply-colorscheme --list-schemes)
scheme="$1"
[ -n "$scheme" ] || exit 1
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

case "$scheme" in
    DockyardDay) tone=day; family=glass-day; kvset=DockyardDay ;;
    Dockyard) tone=night; family=glass; kvset=Dockyard ;;
    BreezeLight) tone=day; breeze=breeze-light ;;
    BreezeDark) tone=night; breeze=breeze-dark ;;
    *) tone= ;;
esac
state="${XDG_STATE_HOME:-$HOME/.local/state}/dockyard"
swap="$state/breeze-swap"
here="$(dirname "$0")"

# Breeze pair: swap the Dockyard pieces for their Breeze equivalents.
if [ -n "$breeze" ]; then
    cur=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
    [ "$cur" = "$scheme" ] || plasma-apply-colorscheme "$scheme"
    mkdir -p "$state"
    touch "$swap"

    pt=$(kreadconfig6 --file plasmarc --group Theme --key name)
    case "$pt" in
        glass|glass-day|glass-opaque|glass-day-opaque|glass-islands|glass-day-islands|breeze-light|breeze-dark)
            if [ "$pt" != "$breeze" ]; then
                case "$pt" in breeze-*) ;; *) echo "plasma=$pt" >> "$swap" ;; esac
                plasma-apply-desktoptheme "$breeze"
            fi ;;
        default) ;;   # follows the color scheme already
    esac

    kv=$(kreadconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme)
    ws=$(kreadconfig6 --file kdeglobals --group KDE --key widgetStyle)
    case "$kv" in
        Dockyard|DockyardGlass|DockyardDay|DockyardDayGlass)
            if [ "$ws" = kvantum ]; then
                echo "style=kvantum" >> "$swap"
                kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
            fi ;;
    esac

    deco=$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme)
    case "$deco" in
        __aurorae__svg__Dockyard|__aurorae__svg__DockyardDay)
            echo "deco=$deco" >> "$swap"
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
            qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true ;;
    esac

    sh "$here/icon-tone.sh" "$tone" >/dev/null 2>&1 || true
    exit 0
fi

# Back from Breeze to a Dockyard scheme: restore only what the Breeze branch swapped.
if [ -n "$tone" ] && [ -f "$swap" ]; then
    if grep -q '^style=kvantum' "$swap"; then
        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
    fi
    if grep -q '^deco=' "$swap"; then
        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__$kvset"
        qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    fi
    if grep -q '^plasma=' "$swap"; then
        pt=$(kreadconfig6 --file plasmarc --group Theme --key name)
        case "$pt" in breeze-light|breeze-dark) plasma-apply-desktoptheme "$family" ;; esac
    fi
    rm -f "$swap"
fi

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

# Icon theme: light-background or dark-background sibling, so button icons stay visible.
sh "$here/icon-tone.sh" "$tone" >/dev/null 2>&1 || true

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
