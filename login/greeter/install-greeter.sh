#!/bin/sh
# PRINTS the root commands that install the Dockyard greeter. It runs none of them.
# Copy the commands you want into a root shell yourself. See GREETER-PLAN.md section 5.
#
# Usage: ./install-greeter.sh [path-to-built-binary]
set -eu

BIN=${1:-/tmp/claude-1000/plm-src/build/bin/plasma-login-greeter}

cat <<EOF
# ---- 1. Install the greeter binary (root) ----------------------------------------------
# Source: $BIN
# The binary must come from a non-/run/data path. /run/data is NTFS fuseblk mode 0777.
sudo install -D -m 0755 -o root -g root "$BIN" \\
     /opt/dockyard/libexec/dockyard-login-greeter

# ---- 2. Install the fallback wrapper (root) ---------------------------------------------
# If the Dockyard greeter exits non-zero, the stock greeter runs, so the login screen never stays blank.
sudo install -D -m 0755 -o root -g root /dev/stdin /opt/dockyard/libexec/dockyard-login-greeter-wrapper <<'WRAPPER'
#!/bin/sh
# Run the Dockyard greeter; if it fails, run the stock one so the login screen never stays blank.
/opt/dockyard/libexec/dockyard-login-greeter "\$@"
rc=\$?
[ "\$rc" -eq 0 ] && exit 0
echo "dockyard greeter exited with \$rc, falling back to stock greeter" >&2
exec /usr/lib/plasma-login-greeter "\$@"
WRAPPER

# ---- 3. Drop-in that points the user unit at the wrapper (root) -------------------------
sudo install -D -m 0644 /dev/stdin /etc/systemd/user/plasma-login.service.d/dockyard.conf <<'DROPIN'
[Service]
ExecStart=
ExecStart=/opt/dockyard/libexec/dockyard-login-greeter-wrapper
DROPIN

# ---- 4. Apply ----------------------------------------------------------------------------
# No reload is needed while user@959 (plasmalogin) is inactive. The greeter appears after
# logging out of Plasma (autologin is on). If the plasmalogin user manager is active,
# restart the login manager from a TTY (this ends any graphical session):
#   sudo systemctl restart plasmalogin.service

# ---- ROLLBACK (run from a TTY, e.g. Ctrl+Alt+F3) ---------------------------------------
# sudo rm /etc/systemd/user/plasma-login.service.d/dockyard.conf
# sudo rmdir /etc/systemd/user/plasma-login.service.d
# sudo systemctl restart plasmalogin.service
# Optional full removal:
# sudo rm -r /opt/dockyard/libexec/dockyard-login-greeter*
EOF
