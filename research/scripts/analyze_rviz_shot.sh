#!/usr/bin/env bash
#
# Pixel statistics of the captured RViz window (is it rendering a scene?).
#
set -uo pipefail

IMG=/workspace/research/logs/wslg_screen_rviz.png

identify "${IMG}"
echo "== unique colors / entropy =="
convert "${IMG}" -format "colors=%k mean=%[fx:mean] std=%[fx:standard_deviation]\n" info:
echo "== dominant colors =="
convert "${IMG}" -resize 50% -depth 8 -format %c histogram:info:- 2>/dev/null | sort -rn | head -6
