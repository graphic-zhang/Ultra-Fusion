#!/usr/bin/env bash
#
# Check WSLg status from inside the WSL distro.
#
set -uo pipefail

echo "DISPLAY=${DISPLAY:-unset}"
ls -la /tmp/.X11-unix/ 2>&1
echo "== weston / xwayland / wslg processes =="
ps aux | grep -iE 'weston|xwayland|wslg' | grep -v grep | head -8
echo "== X socket test =="
if [ -S /tmp/.X11-unix/X0 ]; then
    timeout 3 bash -c 'exec 3<>/dev/tcp/unix:/tmp/.X11-unix/X0' 2>/dev/null \
        && echo "X0 socket connectable" || echo "X0 socket test inconclusive"
fi
echo "== xdpyinfo (host) =="
if command -v xdpyinfo >/dev/null 2>&1; then
    DISPLAY=:0 xdpyinfo 2>&1 | grep -E 'name of display|dimensions' | head -3
else
    echo "xdpyinfo not installed in distro"
fi
