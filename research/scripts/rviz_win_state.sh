#!/usr/bin/env bash
#
# Show all RViz windows in the X tree with size / map state.
#
set -uo pipefail

xwininfo -root -tree 2>/dev/null | grep -iE 'rviz|weston' | head -10

echo "== detail of each rviz window =="
for id in $(xwininfo -root -tree 2>/dev/null | grep -iE '".*rviz' | grep -oE '^ *0x[0-9a-f]+' | tr -d ' '); do
    echo "--- $id ---"
    xwininfo -id "$id" 2>/dev/null | grep -E 'Window id|Map State|Width|Height|Absolute upper-left|Override'
done
