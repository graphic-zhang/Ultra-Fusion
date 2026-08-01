#!/usr/bin/env bash
#
# Interactive Ultra-Fusion ROS2 demo runner (WSL2 + WSLg).
#
# Usage:
#   bash research/scripts/run_uf_ros2.sh [path/to/ros2_bag_dir]
#
# Inside the container (three terminals):
#   1. uf_node
#   2. ros2 bag play
#   3. rviz2
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

IMG="${ULTRAFUSION_IMAGE:-ultrafusion-ros2:0.2.2-local}"
CONFIG="${UF_CONFIG:-/workspace/research/configs/uf_m3dgr_ros2_lvwio_dt0p1.yaml}"
START_OFFSET="${START_OFFSET:-2}"
BAG="${1:-${REPO_ROOT}/research/downloads/data/occlusion01_ros2}"

if ! docker image inspect "${IMG}" >/dev/null 2>&1; then
    echo "Error: image ${IMG} not found. Run: docker pull ${IMG}" >&2
    exit 1
fi
if [ ! -e "${BAG}" ]; then
    echo "Error: rosbag not found: ${BAG}" >&2
    echo "Download the M3DGR Occlusion01 bag (Alipan: https://www.alipan.com/s/r3P6Bcxj7Tu)," >&2
    echo "then convert it (see research/README.md) into research/downloads/data/." >&2
    exit 1
fi

DATA_DIR="$(cd "$(dirname "${BAG}")" && pwd)"

echo "== Ultra-Fusion ROS2 runtime =="
echo "image : ${IMG}"
echo "bag   : ${BAG}"
echo "config: ${CONFIG}  (research variant: lidar-to-imu dt=+0.1 s)"
echo "workspace: ${REPO_ROOT} (mounted at /workspace)"
echo
echo "Inside the container:"
echo "  1) source /opt/ros/humble/setup.bash"
echo "  2) uf_node ${CONFIG} --ros-args -p use_sim_time:=true"
echo "  3) ros2 bag play /data/$(basename "${BAG}") --clock --start-offset ${START_OFFSET}"
echo "  4) rviz2 -d /opt/ultrafusion/rviz/lio_ros2.rviz"
echo
echo "Note: wait ~10-20 s for uf_node initialization before playing the bag."
echo "      --start-offset ${START_OFFSET} skips the bag head where the wheel"
echo "      stream has not started yet (measured data property of M3DGR)."
echo

exec docker run --rm -it --net=host --ipc=host \
    -e "DISPLAY=${DISPLAY:-:0}" \
    -e QT_X11_NO_MITSHM=1 \
    -e "HTTP_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "HTTPS_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "http_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "https_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "NO_PROXY=localhost,127.0.0.1" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "${REPO_ROOT}:/workspace" \
    -v "${DATA_DIR}:/data:ro" \
    "${IMG}" bash
