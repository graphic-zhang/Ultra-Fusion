#!/usr/bin/env bash
#
# Headless smoke test: run uf_node (LVWIO profile) against a short ROS2 bag.
#
# Usage:
#   bash research/scripts/smoke_test_uf.sh [ros2_bag_dir] [rate] [wait_after_s]
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

IMG="ultrafusion-ros2:0.2.2-local"
BAG="${1:-${REPO_ROOT}/research/downloads/data/occlusion01_ros2_test}"
RATE="${2:-2}"
WAIT_AFTER="${3:-60}"
PROFILE="${PROFILE:-uf_m3dgr_ros2_lvwio.yaml}"
START="${START:-0}"
KILL_SIG="${KILL_SIG:--INT}"
if [[ "${PROFILE}" == /* ]]; then
    CONFIG="${PROFILE}"
else
    CONFIG="/opt/ultrafusion/config/m3dgr/${PROFILE}"
fi

docker rm -f uf_smoke >/dev/null 2>&1 || true

echo "== smoke test: image=${IMG} bag=${BAG} rate=${RATE} start=${START} config=${CONFIG}"

START_ARGS=""
if [ "${START}" -gt 0 ]; then
    START_ARGS="--start-offset ${START}"
fi

docker run -d --name uf_smoke --net=host \
    -e "DISPLAY=${DISPLAY:-:0}" \
    -e QT_X11_NO_MITSHM=1 \
    -e "HTTP_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "HTTPS_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "http_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "https_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "NO_PROXY=localhost,127.0.0.1" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "${REPO_ROOT}:/workspace" \
    -v "$(dirname "${BAG}"):/data:ro" \
    "${IMG}" \
    bash -lc "source /opt/ros/humble/setup.bash && uf_node ${CONFIG} --ros-args -p use_sim_time:=true > /tmp/uf.log 2>&1 & UF_PID=\$!; sleep 8; echo '== playing bag =='; ros2 bag play /data/$(basename "${BAG}") --clock --rate ${RATE} ${START_ARGS}; sleep ${WAIT_AFTER}; kill ${KILL_SIG} \${UF_PID} 2>/dev/null || true; sleep 10; mkdir -p /workspace/research/logs; cp /tmp/uf.log /workspace/research/logs/uf_last_run.log; echo '===== UF_NODE LOG (end) ====='; tail -60 /tmp/uf.log; echo '===== SHUTDOWN BLOCK ====='; grep -A3 -E 'Main: loop exited|Saved TUM trajectory|Process thread: exiting' /tmp/uf.log | tail -20"

echo "== container log =="
docker logs -f uf_smoke 2>&1 | tail -120

docker rm -f uf_smoke >/dev/null 2>&1 || true
echo "== smoke test finished =="
