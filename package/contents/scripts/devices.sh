#!/bin/sh
# Battery levels of devices other than this machine's own battery, one per line:
#   kind<TAB>name<TAB>percent<TAB>charging (1 or 0)
# Peripherals come from UPower (mice, keyboards, headsets, controllers), phones from
# KDE Connect when it is installed and the phone is reachable. Prints nothing when
# there is none; every failure is silent.

if command -v upower >/dev/null 2>&1; then
    for p in $(upower -e 2>/dev/null); do
        case "$p" in
            *line_power*|*DisplayDevice*) continue ;;
        esac
        info=$(upower -i "$p" 2>/dev/null)
        # The machine's own battery is a power supply; peripherals are not.
        echo "$info" | grep -qE 'power supply: *yes' && continue
        pct=$(echo "$info" | sed -n 's/^ *percentage: *\([0-9][0-9]*\)%.*/\1/p' | head -1)
        [ -z "$pct" ] && continue
        kind=$(echo "$info" | sed -n 's/^  \([a-z-][a-z-]*\)$/\1/p' | head -1)
        model=$(echo "$info" | sed -n 's/^ *model: *//p' | head -1)
        vendor=$(echo "$info" | sed -n 's/^ *vendor: *//p' | head -1)
        name=$(echo "$vendor $model" | sed 's/^ *//; s/ *$//')
        [ -z "$name" ] && name="$kind"
        state=$(echo "$info" | sed -n 's/^ *state: *//p' | head -1)
        charging=0
        [ "$state" = "charging" ] && charging=1
        printf '%s\t%s\t%s\t%s\n' "$kind" "$name" "$pct" "$charging"
    done
fi

if command -v kdeconnect-cli >/dev/null 2>&1; then
    kdeconnect-cli -a --id-name-only 2>/dev/null | while read -r id name; do
        [ -z "$id" ] && continue
        base="/modules/kdeconnect/devices/$id"
        pct=$(qdbus6 org.kde.kdeconnect "$base/battery" org.kde.kdeconnect.device.battery.charge 2>/dev/null)
        case "$pct" in ''|*[!0-9]*) continue ;; esac
        charging=0
        [ "$(qdbus6 org.kde.kdeconnect "$base/battery" org.kde.kdeconnect.device.battery.isCharging 2>/dev/null)" = "true" ] && charging=1
        kind=$(qdbus6 org.kde.kdeconnect "$base" org.kde.kdeconnect.device.type 2>/dev/null)
        printf '%s\t%s\t%s\t%s\n' "${kind:-phone}" "$name" "$pct" "$charging"
    done
fi
exit 0
