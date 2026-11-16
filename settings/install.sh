#!/usr/bin/env bash
# Build the KCM host plugin (needs cmake, ninja, g++, Qt6 and KF6 KCMUtils dev files) and
# link the settings app into ~/.local so it shows in the app launcher.
set -euo pipefail
d="$(cd "$(dirname "$0")" && pwd)"
/usr/bin/cmake -S "$d/kcmhost" -B "$d/build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
/usr/bin/ninja -C "$d/build"
mkdir -p ~/.local/bin ~/.local/share/applications ~/.local/share/icons/hicolor
# App icon (dev.aryan.dockyard.settings): rendered PNGs plus the scalable SVG, copied over any older copy.
cp -r "$d/icons/app/hicolor/." ~/.local/share/icons/hicolor/
touch ~/.local/share/icons/hicolor
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor >/dev/null 2>&1 || true
ln -sf "$d/dockyard-settings" ~/.local/bin/dockyard-settings
sed "s|^Exec=.*|Exec=$d/dockyard-settings|" "$d/dev.aryan.dockyard.settings.desktop" > ~/.local/share/applications/dev.aryan.dockyard.settings.desktop
"$d/redirect-system-settings.sh" on
"$d/../theme/install-accent-watch.sh" || true
update-desktop-database ~/.local/share/applications 2>/dev/null || true
kbuildsycoca6 >/dev/null 2>&1 || true
# The icon copy above is the rose original; re-apply the current accent to it.
"$d/../theme/apply-accent-all.sh" --force >/dev/null 2>&1 || true
echo "Installed. Run: dockyard-settings [kcm_id]"
