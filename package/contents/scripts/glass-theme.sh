#!/bin/sh
# Switch the Dockyard look between solid and frosted: the Plasma theme (glass-opaque or
# glass) and, when Dockyard is the app style, the Kvantum theme (Dockyard for solid
# windows, DockyardGlass for translucent ones). Only acts when a Dockyard Plasma theme is
# already active, so another theme is never replaced.
# Usage: glass-theme.sh opaque|frosted
case "$1" in
    opaque) want=glass-opaque; kv=Dockyard ;;
    frosted) want=glass; kv=DockyardGlass ;;
    *) echo "usage: $0 opaque|frosted" >&2; exit 1 ;;
esac
cur=$(kreadconfig6 --file plasmarc --group Theme --key name)
case "$cur" in
    glass|glass-opaque) ;;
    *) echo "active theme is '$cur', left alone"; exit 0 ;;
esac
dirs="${XDG_DATA_HOME:-$HOME/.local/share} /usr/share"
installed=0
for d in $dirs; do
    [ -d "$d/plasma/desktoptheme/$want" ] && installed=1
done
if [ "$installed" = 0 ]; then
    echo "theme $want is not installed; run install-all.sh" >&2
    exit 1
fi
plasma-apply-desktoptheme "$want"

# Kvantum follows only while Dockyard is the app style.
kvcur=$(kreadconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme)
case "$kvcur" in
    Dockyard|DockyardGlass)
        [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/$kv" ] && kvantummanager --set "$kv" ;;
esac
