#!/usr/bin/env bash
#
# Install the Ultra-Fusion ROS2 .deb into the runtime container and verify.
# Idempotent: removes a previous uf_test container if present.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

IMG="maotiandocker/ultrafusion-ros2:0.2.0"
DEB="ultrafusion-ros2_0.2.2_amd64.deb"
DEB_PATH="/workspace/research/downloads/${DEB}"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

if [ ! -f "${REPO_ROOT}/research/downloads/${DEB}" ]; then
    echo "Error: ${DEB} not found. Run research/scripts/fetch_deb.sh first." >&2
    exit 1
fi

docker rm -f uf_test >/dev/null 2>&1 || true

echo "== Starting container: apt deps + install ${DEB} ..."
docker run --rm -d --name uf_test \
    --net=host \
    -e "HTTP_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "HTTPS_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "http_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "https_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "NO_PROXY=localhost,127.0.0.1,172.16.0.0/12,192.168.0.0/16,10.0.0.0/8" \
    -v "${REPO_ROOT}:/workspace" \
    "${IMG}" \
    bash -lc "apt-get update && apt-get install -y ros-humble-ros2service ros-humble-std-srvs && cd /workspace && ./scripts/install_ultrafusion_ros2_deb.sh --deb ${DEB_PATH} && echo INSTALL_OK && which uf_node && ls /opt/ultrafusion/config"

echo "== Container log =="
docker logs -f uf_test 2>&1 | tail -40

echo
echo "Note: container exits after setup; start a persistent one with run_uf_ros2.sh."
