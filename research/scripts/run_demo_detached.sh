#!/usr/bin/env bash
#
# Launch the Ultra-Fusion ROS2 LVWIO demo detached: RViz2 (WSLg) + uf_node
# + ros2 bag play, so the visualization pops up on the Windows desktop and
# keeps running in the background.
#
# Usage: bash research/scripts/run_demo_detached.sh
# Stop:  docker rm -f uf_demo
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

IMG="ultrafusion-ros2:0.2.2-local"
CONFIG="/workspace/research/configs/uf_m3dgr_ros2_lvwio_dt0p1.yaml"
BAG="/data/occlusion01_ros2"
RATE="${RATE:-1}"
START_OFFSET="${START_OFFSET:-2}"
PRE_PLAY_WAIT="${PRE_PLAY_WAIT:-20}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
READ_AHEAD="${READ_AHEAD:-1000}"

docker rm -f uf_demo >/dev/null 2>&1 || true

docker run -d --name uf_demo --net=host \
    -e "DISPLAY=:0" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "${REPO_ROOT}:/workspace" \
    -v "${REPO_ROOT}/research/downloads/data:/data:ro" \
    "${IMG}" \
    bash -c "source /opt/ros/humble/setup.bash
rviz2 -d /opt/ultrafusion/rviz/lio_ros2.rviz > /tmp/rviz.log 2>&1 &
for i in 1 2 3; do
  echo \"=== attempt \$i ===\"
  uf_node ${CONFIG} --ros-args -p use_sim_time:=true > /tmp/uf.log 2>&1 &
  UF_PID=\$!
  sleep ${PRE_PLAY_WAIT}
  ros2 bag play ${BAG} --clock --start-offset ${START_OFFSET} --rate ${RATE} --read-ahead-queue-size ${READ_AHEAD} &
  PLAY_PID=\$!
  while kill -0 \${PLAY_PID} 2>/dev/null && kill -0 \${UF_PID} 2>/dev/null; do
    sleep 2
  done
  if ! kill -0 \${UF_PID} 2>/dev/null; then
    echo \"uf_node exited during attempt \$i; aborting playback and retrying\"
    kill \${PLAY_PID} 2>/dev/null || true
    wait \${PLAY_PID} 2>/dev/null || true
    sleep 3
    continue
  fi
  echo \"uf_node survived the bag; demo stays alive\"
  break
done
tail -f /dev/null"

echo "uf_demo container started (name=uf_demo)."
echo "Logs: docker logs uf_demo | tail -100"
