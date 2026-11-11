#!/bin/sh
# Stop hook: when anything in package/ or kwin-script/ changed since the last
# install, reinstall the plasmoid and replace the running plasmashell.
cd "$(dirname "$0")/../.." || exit 0
stamp=.claude/.last-install
if [ -f "$stamp" ] && [ -z "$(find package kwin-script -type f -newer "$stamp" -print -quit)" ]; then
    exit 0
fi
touch "$stamp"
./install.sh >/dev/null 2>&1 || { echo '{"systemMessage": "Dockyard: install.sh failed"}'; exit 0; }
setsid plasmashell --replace >/dev/null 2>&1 < /dev/null &
echo '{"systemMessage": "Dockyard installed, plasmashell restarted"}'
