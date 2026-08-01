#!/usr/bin/env bash
set -uo pipefail
ps -eo pid,stat,comm | grep -E 'rviz|uf_node|ros2' | head -8
