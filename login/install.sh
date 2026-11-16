#!/bin/sh
# Install the Dockyard login screen wallpaper and the Plymouth boot splash. Needs root.
# The lock screen ships inside the look-and-feel (theme/install-global.sh). The greeter needs
# a build: see greeter/build.sh and greeter/install-greeter.sh.
# Usage: login/install.sh [--wallpaper] [--plymouth]   (no option installs both)
# The wallpaper uses the id online.knowmad.shaderwallpaper because the Login Screen page only lists allowlisted ids; its name shows as Dockyard.
set -e
[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"
cd "$(dirname "$0")"

wall=0; ply=0
for a in "$@"; do
    case "$a" in
        --wallpaper) wall=1 ;;
        --plymouth) ply=1 ;;
        *) echo "unknown option: $a" >&2; exit 1 ;;
    esac
done
[ "$wall$ply" = 00 ] && wall=1 && ply=1

if [ "$wall" = 1 ]; then
    rm -rf /usr/share/plasma/wallpapers/online.knowmad.shaderwallpaper
    cp -r wallpaper /usr/share/plasma/wallpapers/online.knowmad.shaderwallpaper
    echo "Installed the login wallpaper."
fi
if [ "$ply" = 1 ]; then
    rm -rf /usr/share/plymouth/themes/dockyard
    cp -r plymouth /usr/share/plymouth/themes/dockyard
    plymouth-set-default-theme -R dockyard   # -R rebuilds the initramfs
    echo "Installed the boot splash. Reboot to see it."
fi
