#!/bin/sh
# Switch the icon theme to its light-background or dark-background sibling, so toolbar and button
# icons stay visible when the look flips. Tela-dark <-> Tela-light, breeze-dark <-> breeze.
# Only acts on a theme that has such a sibling installed; any other icon theme is left alone.
# Usage: icon-tone.sh day|night
tone="$1"
cur=$(kreadconfig6 --file kdeglobals --group Icons --key Theme)
[ -n "$cur" ] || exit 0
base=$(printf '%s' "$cur" | sed -E 's/[-_ ]?([Dd]ark|[Ll]ight)$//')
has() {
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}/icons" "$HOME/.icons" /usr/share/icons; do
        [ -f "$d/$1/index.theme" ] && return 0
    done
    return 1
}
if [ "$tone" = day ]; then
    for c in "$base-light" "${base}_Light" "$base"; do has "$c" && want="$c" && break; done
else
    for c in "$base-dark" "${base}_Dark" "$base"; do has "$c" && want="$c" && break; done
fi
[ -n "$want" ] && [ "$want" != "$cur" ] || exit 0
# Never replace an icon theme that is not a variant of the current one.
[ "$base" = "$(printf '%s' "$cur" | sed -E 's/[-_ ]?([Dd]ark|[Ll]ight)$//')" ] || exit 0
exec /usr/lib/plasma-changeicons "$want"
