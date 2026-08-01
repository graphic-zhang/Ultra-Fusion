#!/usr/bin/env bash
#
# Show DISPLAY and its origin (for WSLg troubleshooting).
#
set -uo pipefail

echo "DISPLAY=${DISPLAY:-unset}"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-unset}"
grep -n "DISPLAY" ~/.bashrc ~/.profile ~/.bash_profile /etc/profile 2>/dev/null | head -10 || true
ls -la /tmp/.X11-unix/ 2>&1
