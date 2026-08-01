#!/usr/bin/env bash
#
# Capture the WSLg virtual display (X root window) from inside the container
# and save it into the workspace so we can inspect what Weston is showing.
#
set -uo pipefail

apt-get install -y -q imagemagick x11-apps >/dev/null 2>&1 || true

export DISPLAY="${DISPLAY:-:0}"
OUT=/workspace/research/logs/wslg_screen

echo "== xdpyinfo =="
xdpyinfo 2>&1 | grep -E 'name of display|dimensions|depth of root|number of screens' | head -5

echo "== xwd capture =="
xwd -root -out "${OUT}.xwd" 2>&1
if [ -f "${OUT}.xwd" ]; then
    convert "${OUT}.xwd" "${OUT}.png" 2>&1
    ls -la "${OUT}.png" 2>&1
else
    echo "xwd failed"
fi

echo "== import capture (fallback) =="
import -window root "${OUT}_import.png" 2>&1
ls -la "${OUT}_import.png" 2>&1

echo "== rviz window capture =="
RVIZ_ID="$(xwininfo -root -tree 2>/dev/null | grep -oE '0x[0-9a-f]+ .*RViz' | head -1 | awk '{print $1}')"
echo "rviz window id: ${RVIZ_ID:-none}"
if [ -n "${RVIZ_ID}" ]; then
    xwd -id "${RVIZ_ID}" -out "${OUT}_rviz.xwd" 2>&1
    if [ -f "${OUT}_rviz.xwd" ]; then
        convert "${OUT}_rviz.xwd" "${OUT}_rviz.png" 2>&1
        ls -la "${OUT}_rviz.png" 2>&1
    fi
fi
