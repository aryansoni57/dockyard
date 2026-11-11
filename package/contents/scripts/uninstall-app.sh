#!/bin/sh
# Finds how an app was installed and uninstalls it the same way, for the
# Uninstall item in the dock and launcher menus.
#
#   uninstall-app.sh detect <launcher>  prints "kind<TAB>label", e.g. "pacman<TAB>Pacman: kate"
#   uninstall-app.sh run <launcher>     uninstalls; asks first, in a terminal or Steam's own dialog
#
# <launcher> is "applications:id.desktop", "id.desktop" or "file:///path/id.desktop".
# Kinds: flatpak, snap, steam, appimage, pacman, entry (only a menu entry we can remove).

mode="$1"
launcher="$2"

find_desktop() {
    case "$1" in
        file://*) f="${1#file://}"; [ -r "$f" ] && echo "$f"; return ;;
        /*) [ -r "$1" ] && echo "$1"; return ;;
        *://*) return ;;
    esac
    id="${1#applications:}"
    case "$id" in *.desktop) ;; *) id="$id.desktop" ;; esac
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}" $(echo "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" | tr : ' '); do
        if [ -r "$d/applications/$id" ]; then
            echo "$d/applications/$id"
            return
        fi
    done
}

key() {
    sed -n "/^\[Desktop Entry\]/,/^\[/{s/^$1=//p}" "$2" | head -n 1
}

# Sets kind, target and label for the desktop file $1.
detect() {
    file="$1"
    exec_line=$(key Exec "$file")
    name=$(key Name "$file")
    kind=""
    target=""

    fp=$(key X-Flatpak "$file")
    if [ -n "$fp" ]; then
        kind=flatpak target="$fp"
    elif echo "$file" | grep -q '/var/lib/snapd/desktop/'; then
        kind=snap target=$(basename "$file" .desktop | cut -d_ -f1)
    elif echo "$exec_line" | grep -q 'steam://rungameid/'; then
        kind=steam target=$(echo "$exec_line" | sed -n 's|.*steam://rungameid/\([0-9]*\).*|\1|p')
    elif image=$(echo "$exec_line" | grep -oiE '/[^"]*\.appimage' | head -n 1) && [ -n "$image" ]; then
        kind=appimage target="$image"
    elif command -v pacman >/dev/null && pkg=$(pacman -Qqo "$file" 2>/dev/null) && [ -n "$pkg" ]; then
        kind=pacman target="$pkg"
    else
        case "$file" in
            "${XDG_DATA_HOME:-$HOME/.local/share}"/*) kind=entry target="$file" ;;
        esac
    fi

    case "$kind" in
        flatpak) label="Flatpak: $target" ;;
        snap) label="Snap: $target" ;;
        steam) label="Steam" ;;
        appimage) label="AppImage: $(basename "$target")" ;;
        pacman) label="Pacman: $target" ;;
        entry) label="Menu entry only" ;;
    esac
}

terminal() {
    title="$1"
    shift
    if command -v konsole >/dev/null; then
        setsid -f konsole -p tabtitle="$title" -e "$@" >/dev/null 2>&1
    elif command -v x-terminal-emulator >/dev/null; then
        setsid -f x-terminal-emulator -e "$@" >/dev/null 2>&1
    else
        setsid -f xterm -T "$title" -e "$@" >/dev/null 2>&1
    fi
}

ask() {
    printf '%s [y/N] ' "$1"
    read -r answer
    case "$answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

file=$(find_desktop "$launcher")
[ -n "$file" ] || exit 0
detect "$file"

case "$mode" in
    detect)
        [ -n "$kind" ] && printf '%s\t%s\n' "$kind" "$label"
        ;;
    run)
        case "$kind" in
            steam) setsid -f xdg-open "steam://uninstall/$target" >/dev/null 2>&1 ;;
            "") ;;
            *) terminal "Uninstall $name" sh "$0" inner "$launcher" ;;
        esac
        ;;
    inner)
        # Runs inside the terminal, so every step can ask before it changes anything.
        echo "Uninstall $name"
        echo "Installed with: $label"
        echo
        case "$kind" in
            flatpak)
                flatpak uninstall "$target"
                ;;
            snap)
                ask "Remove the snap $target?" && sudo snap remove "$target"
                ;;
            pacman)
                sudo pacman -Rns "$target"
                ;;
            appimage)
                if flatpak info it.mijorus.gearlever >/dev/null 2>&1; then
                    ask "Move $target and its menu entry to the trash with Gear Lever?" \
                        && flatpak run it.mijorus.gearlever --remove "$target"
                else
                    ask "Move $target and its menu entry to the trash?" \
                        && gio trash "$target" "$file"
                fi
                ;;
            entry)
                echo "Dockyard could not tell which package installed this app."
                echo "Menu entry: $file"
                echo "Command:    $exec_line"
                echo
                ask "Move the menu entry to the trash? The program itself stays." && gio trash "$file"
                ;;
        esac
        echo
        printf 'Press Enter to close.'
        read -r _
        ;;
esac
