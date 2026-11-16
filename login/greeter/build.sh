#!/bin/sh
# Build the Dockyard greeter (plasma-login-greeter) from the upstream v6.8.2 tree plus this overlay.
# Never run as root. Never runs `cmake --install`. Install with install-greeter.sh (prints commands only).
#
# Usage: WORK=/tmp/claude-1000/plm-src ./build.sh
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-/tmp/claude-1000/plm-src}
TAG=v6.8.2
SRC=$WORK/src
BLD=$WORK/build
ECM_PREFIX=$HOME/.local/opt/ecm

if [ "$(id -u)" -eq 0 ]; then
    echo "build.sh: refusing to run as root" >&2
    exit 1
fi

# (a) upstream source, cloned once
if [ ! -d "$SRC" ]; then
    git clone --depth 1 --branch "$TAG" https://invent.kde.org/plasma/plasma-login-manager.git "$SRC"
fi

# (b) overlay: replace the greeter's QML, main.cpp and CMakeLists.txt; the C++ backend stays upstream
GREETER=$SRC/src/frontend/greeter
cp -r "$HERE/qml" "$GREETER/"
cp "$HERE/main.cpp" "$HERE/CMakeLists.txt" "$HERE/glassblur.h" "$HERE/glassblur.cpp" "$GREETER/"

# (c) configure and build only the greeter target (ECM must be in $ECM_PREFIX, see GREETER-PLAN.md 2.2)
cmake -S "$SRC" -B "$BLD" -G Ninja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_PREFIX_PATH="$ECM_PREFIX" \
      -DCMAKE_INSTALL_PREFIX=/usr -DKDE_INSTALL_LIBEXECDIR=lib \
      -DBUILD_TESTING=OFF -DINSTALL_PAM_CONFIGURATION=OFF
cmake --build "$BLD" --target plasma-login-greeter

# (d) report the binary; install-greeter.sh prints the root commands that copy it
echo "built: $BLD/bin/plasma-login-greeter"
