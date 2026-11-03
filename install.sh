#!/usr/bin/env bash
# Install or upgrade the plasmoid for the current user.
set -euo pipefail
cd "$(dirname "$0")"

if kpackagetool6 -t Plasma/Applet -s dev.aryan.dock >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u package
else
    kpackagetool6 -t Plasma/Applet -i package
fi

# Meta+1..9 for the dock's apps come from a KWin script (see kwin-script/contents/code/main.js).
if kpackagetool6 -t KWin/Script -s dockyardshortcuts >/dev/null 2>&1; then
    kpackagetool6 -t KWin/Script -u kwin-script
else
    kpackagetool6 -t KWin/Script -i kwin-script
fi
kwriteconfig6 --file kwinrc --group Plugins --key dockyardshortcutsEnabled true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# Plasma keeps Meta+1..9 on the stock Task Manager's entries even with no Task Manager
# in a panel. Clear them so the KWin script owns the keys. Re-adding a Task Manager
# needs them set again in System Settings > Shortcuts > plasmashell.
for n in 1 2 3 4 5 6 7 8 9; do
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.setForeignShortcutKeys \
        "['plasmashell', 'activate task manager entry $n', '', '']" "@a(ai) []" >/dev/null 2>&1 || true
done

echo "Installed. Restart plasmashell to reload: systemctl --user restart plasma-plasmashell"
