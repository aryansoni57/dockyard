#!/usr/bin/env bash
# Make launchers that start System Settings (the app menu entry, KRunner module entries, widget
# "Configure…" links, systemsettings:// links) start Dockyard Settings instead. Per-user override files
# only; /usr is untouched. Usage: redirect-system-settings.sh [on|off]   (default on)
set -euo pipefail
d="$(cd "$(dirname "$0")" && pwd)"
apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mark="X-Dockyard-Override=true"
mkdir -p "$apps"
# Remove what an earlier run wrote (only files carrying our marker).
{ grep -l -s "^$mark" "$apps"/*.desktop 2>/dev/null || true; } | xargs -r rm -f
if [ "${1:-on}" = off ]; then
    update-desktop-database "$apps" 2>/dev/null || true
    echo "System Settings launchers restored."
    exit 0
fi
n=0
for f in /usr/share/applications/systemsettings.desktop /usr/share/applications/kcm_*.desktop /usr/share/applications/org.kde.plasma.settings.open.desktop; do
    [ -f "$f" ] || continue
    out="$apps/$(basename "$f")"
    # systemsettings <module...> and plasma-open-settings %u both become dockyard-settings with the same arguments.
    sed -E -e "s|^Exec=systemsettings( .*)?\$|Exec=$d/dockyard-settings\1|" \
           -e "s|^Exec=.*plasma-open-settings.*\$|Exec=$d/dockyard-settings %u|" "$f" > "$out"
    grep -q "^Exec=$d/dockyard-settings" "$out" || { rm -f "$out"; continue; }
    # The generic System Settings entries show the Dockyard Settings icon (only the first Icon=, the
    # main entry; action icons stay). kcm_* entries keep their own module icons.
    case "$(basename "$f")" in
        systemsettings.desktop|org.kde.plasma.settings.open.desktop)
            sed -i '0,/^Icon=/s|^Icon=.*|Icon=dev.aryan.dockyard.settings|' "$out" ;;
    esac
    printf '%s\n' "$mark" >> "$out"
    n=$((n + 1))
done
update-desktop-database "$apps" 2>/dev/null || true
echo "Redirected $n launchers to Dockyard Settings. Undo: $d/redirect-system-settings.sh off"
