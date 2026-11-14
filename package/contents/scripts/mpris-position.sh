#!/bin/sh
# Prints "position length" in microseconds for the MPRIS player whose Identity is $1
# (position 0 and length 0 when it reports none). Plasma's own player model does not
# refresh a browser's position, so the launcher dashboard asks the player directly.
[ -n "$1" ] || exit 0
command -v qdbus6 >/dev/null 2>&1 || exit 0
for n in $(qdbus6 2>/dev/null | sed -n 's/^ *\(org\.mpris\.MediaPlayer2\..*\)$/\1/p'); do
    id=$(qdbus6 "$n" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Identity 2>/dev/null)
    [ "$id" = "$1" ] || continue
    pos=$(qdbus6 "$n" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Position 2>/dev/null)
    len=$(qdbus6 "$n" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata 2>/dev/null | sed -n 's/^mpris:length: *//p' | head -1)
    echo "${pos:-0} ${len:-0}"
    exit 0
done
