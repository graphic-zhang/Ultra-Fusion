#!/usr/bin/env bash
#
# Restart RViz inside the demo container with a screen-fitting geometry.
#
# shellcheck disable=SC1091
source /opt/ros/humble/setup.bash

set -uo pipefail

pkill -f "rviz2" || true
sleep 3

export DISPLAY="${DISPLAY:-:0}"
export QT_X11_NO_MITSHM=1

rviz2 -geometry 1600x880+100+60 -d /opt/ultrafusion/rviz/lio_ros2.rviz \
    > /tmp/rviz.log 2>&1 &

sleep 12

RVIZ_ID="$(xwininfo -root -tree 2>/dev/null | grep -oE '0x[0-9a-f]+ .*RViz' | head -1 | awk '{print $1}')"
echo "rviz window id: ${RVIZ_ID:-none}"
if [ -n "${RVIZ_ID}" ]; then
    xwininfo -id "${RVIZ_ID}" | grep -E 'Map State|Width|Height|Absolute upper-left' | head -6
    xwd -id "${RVIZ_ID}" -out /workspace/research/logs/wslg_screen_rviz2.png 2>&1
fi
