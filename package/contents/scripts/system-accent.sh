#!/bin/sh
# Set or clear the accent color system-wide, so apps and Plasma follow the dock's accent:
#   - the Plasma color scheme accent (apps, settings), and
#   - the colors file of the Dockyard Plasma themes (glass, glass-opaque), which the
#     volume pop-up and other Plasma surfaces read. Plasma reads it at startup, so
#     plasmashell is restarted afterwards.
# Usage: system-accent.sh '#rrggbb'   set it
#        system-accent.sh reset       put the original scheme and theme colors back
themes="glass glass-opaque"
themedir="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme"
keep="${XDG_STATE_HOME:-$HOME/.local/state}/dockyard/theme-colors"

# Rewrite the theme colors from the saved originals (so picks never compound), or restore them.
# $1 is "#rrggbb" or "reset". Prints "changed" when a file was written.
plasma_theme() {
    changed=
    if [ "$1" != reset ]; then
        r=$(printf '%d' "0x$(echo "$1" | cut -c2-3)")
        g=$(printf '%d' "0x$(echo "$1" | cut -c4-5)")
        b=$(printf '%d' "0x$(echo "$1" | cut -c6-7)")
        accent="$r,$g,$b"
        # Selection fills carry white text, so they take a darker shade of the accent.
        sel="$((r * 72 / 100)),$((g * 72 / 100)),$((b * 72 / 100))"
    fi
    for t in $themes; do
        f="$themedir/$t/colors"
        [ -f "$f" ] || continue
        if [ "$1" = reset ]; then
            if [ -f "$keep/$t.colors" ]; then
                cp "$keep/$t.colors" "$f" && changed=changed
            fi
            continue
        fi
        mkdir -p "$keep"
        [ -f "$keep/$t.colors" ] || cp "$f" "$keep/$t.colors"
        sed -e "s/10,132,255/$accent/g" -e "s/0,113,227/$sel/g" "$keep/$t.colors" > "$f.tmp" \
            && mv "$f.tmp" "$f" && changed=changed
    done
    echo "$changed"
}

# Plasma reads the theme colors at startup. Detached, because plasmashell may be what ran this.
# Under systemd a bare "plasmashell --replace" lives in the plasma-plasmashell cgroup, and
# systemd kills it when the old process exits. Restart the unit from a transient one instead.
restart_shell() {
    if systemctl --user is-active --quiet plasma-plasmashell.service \
        && systemd-run --user --quiet --collect sh -c 'sleep 1; systemctl --user restart plasma-plasmashell.service' 2>/dev/null; then
        return
    fi
    setsid sh -c 'sleep 1; plasmashell --replace' >/dev/null 2>&1 &
}

case "$1" in
    "#"??????)
        plasma-apply-colorscheme --accent-color "$1" || exit $?
        # Bright accents make Plasma pick black selection text, but Kvantum still draws its own
        # dark selection fill, so the text turns unreadable. Dockyard keeps white text on selections.
        for key in ForegroundNormal ForegroundActive ForegroundLink ForegroundVisited; do
            kwriteconfig6 --file kdeglobals --group Colors:Selection --key "$key" 255,255,255
        done
        kwriteconfig6 --file kdeglobals --group Colors:Selection --key ForegroundInactive 230,230,235
        # Tell running apps the palette changed.
        dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0
        [ -n "$(plasma_theme "$1")" ] && restart_shell ;;
    reset)
        scheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
        if [ -n "$scheme" ]; then
            kwriteconfig6 --file kdeglobals --group General --key AccentColor --delete
            # Re-applying the scheme that is already active does nothing, so switch away and back.
            if [ "$scheme" = BreezeDark ]; then other=BreezeLight; else other=BreezeDark; fi
            plasma-apply-colorscheme "$other" >/dev/null 2>&1
            plasma-apply-colorscheme "$scheme"
        fi
        [ -n "$(plasma_theme reset)" ] && restart_shell ;;
    *)
        echo "usage: $0 '#rrggbb'|reset" >&2; exit 1 ;;
esac
