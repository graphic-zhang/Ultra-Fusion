#!/usr/bin/env bash
#
# Diagnose RViz window mapping inside the demo container (WSLg/X11).
#
set -uo pipefail

apt-get install -y -q x11-utils >/dev/null 2>&1 || true

echo "DISPLAY=${DISPLAY:-unset}"
echo "== xlsclients =="
xlsclients 2>&1 | head -10
echo "== root window tree =="
xwininfo -root -tree 2>&1 | head -40
echo "== rviz process =="
ps -eo pid,stat,comm | grep rviz | head -3
