#!/usr/bin/env bash
# Re-colour the whole Dockyard system around one accent.
# Usage: apply-accent-all.sh [#rrggbb] [--force]   (default: the system accent in kdeglobals)
#
#   1. gen.py regenerates the Kvantum themes, color schemes, Aurorae decorations and
#      look-and-feel (splash) with DOCKYARD_ACCENT, into a cache folder.
#   2. They are copied over the installed Dockyard files (only those; other themes are untouched)
#      and reloaded if a Dockyard one is active.
#   3. Every script in accent.d/ then colours one more place (Plasma themes, notifications, GTK, ...).
#      They get ACCENT in the environment and must never fail the run.
#
# Runs again only when the accent changed (state file), so it is safe to call from a file watcher.
set -uo pipefail
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/dockyard"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/dockyard/accent-theme"
mkdir -p "$state"

force=0
accent=""
for a in "$@"; do
    case "$a" in
        --force) force=1 ;;
        \#*) accent="$a" ;;
    esac
done
if [ -z "$accent" ]; then
    # The system accent: kdeglobals AccentColor (r,g,b), else the focus colour of the active scheme.
    rgb=$(kreadconfig6 --file kdeglobals --group General --key AccentColor 2>/dev/null)
    [ -n "$rgb" ] || rgb=$(kreadconfig6 --file kdeglobals --group Colors:Window --key DecorationFocus 2>/dev/null)
    IFS=, read -r r g b <<< "$rgb"
    [[ "${r:-x}" =~ ^[0-9]+$ && "${g:-x}" =~ ^[0-9]+$ && "${b:-x}" =~ ^[0-9]+$ ]] || { echo "no system accent found" >&2; exit 1; }
    accent=$(printf '#%02x%02x%02x' "$r" "$g" "$b")
fi
accent=$(printf '%s' "$accent" | tr 'A-F' 'a-f')
[[ "$accent" =~ ^#[0-9a-f]{6}$ ]] || { echo "bad accent: $accent" >&2; exit 1; }

# One run at a time (the file watcher can fire twice), and skip an unchanged accent.
exec 8>"$state/accent.lock"
flock -n 8 || exit 0
if [ "$force" = 0 ] && [ "$(cat "$state/accent-applied" 2>/dev/null)" = "$accent" ]; then
    exit 0
fi
export ACCENT="$accent" DOCKYARD_ACCENT="$accent"

# 1. Generate
rm -rf "$cache"; mkdir -p "$cache"
DOCKYARD_OUT="$cache" python3 "$here/gen.py" >/dev/null || { echo "gen.py failed" >&2; exit 1; }

# 2. Install over the Dockyard files only (merge: the hand-written lock screen, previews and logo stay)
cur_kv=$(kreadconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme 2>/dev/null)
for kv in Dockyard DockyardGlass DockyardDay DockyardDayGlass; do
    mkdir -p "$config/Kvantum/$kv"; cp "$cache/kvantum/$kv/"* "$config/Kvantum/$kv/"
done
mkdir -p "$data/color-schemes"
cp "$cache/color-schemes/Dockyard.colors" "$cache/color-schemes/DockyardDay.colors" "$data/color-schemes/"
mkdir -p "$data/aurorae/themes"
for d in Dockyard DockyardDay; do mkdir -p "$data/aurorae/themes/$d"; cp -r "$cache/aurorae/$d/." "$data/aurorae/themes/$d/"; done
for l in dev.aryan.dockyard dev.aryan.dockyard.day; do
    mkdir -p "$data/plasma/look-and-feel/$l"; cp -r "$cache/look-and-feel/$l/." "$data/plasma/look-and-feel/$l/"
done

# Reload what is active. Kvantum and the decoration keep a loaded theme until it changes.
case "$cur_kv" in Dockyard|DockyardGlass|DockyardDay|DockyardDayGlass) kvantummanager --set "$cur_kv" >/dev/null 2>&1 ;; esac
scheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)
case "$scheme" in Dockyard|DockyardDay) plasma-apply-colorscheme --accent-color "$accent" "$scheme" >/dev/null 2>&1 ;; esac
deco=$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme 2>/dev/null)
case "$deco" in
    __aurorae__svg__Dockyard|__aurorae__svg__DockyardDay)
        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
        qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
        qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 ;;
esac

# 3. Everything else
for s in "$here"/accent.d/*.sh; do
    [ -f "$s" ] || continue
    sh "$s" >/dev/null 2>&1 || echo "accent.d/$(basename "$s") failed" >&2
done

printf '%s' "$accent" > "$state/accent-applied"
echo "Dockyard accent applied: $accent"
