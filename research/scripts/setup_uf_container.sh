#!/usr/bin/env bash
#
# Build a local runtime image: base image + missing apt deps + Ultra-Fusion
# ROS2 .deb, then commit it as ultrafusion-ros2:0.2.2-local.
# Idempotent: removes a previous uf_build container if present.
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

docker rm -f uf_build >/dev/null 2>&1 || true

echo "== Starting container: apt deps + install ${DEB} ..."
docker run -d --name uf_build \
    --net=host \
    -e "HTTP_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "HTTPS_PROXY=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "http_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "https_proxy=http://${PROXY_HOST}:${PROXY_PORT}" \
    -e "NO_PROXY=localhost,127.0.0.1,172.16.0.0/12,192.168.0.0/16,10.0.0.0/8" \
    -v "${REPO_ROOT}:/workspace" \
    "${IMG}" \
    bash -lc "apt-get update && apt-get install -y ros-humble-ros2service ros-humble-std-srvs && cd /workspace && ./scripts/install_ultrafusion_ros2_deb.sh --deb ${DEB_PATH} && echo BUILD_OK && which uf_node"

echo "== Container log =="
docker logs -f uf_build 2>&1 | tail -40

echo
CODE="$(docker inspect uf_build --format '{{.State.ExitCode}}' 2>/dev/null || echo 1)"
if [ "${CODE}" = "0" ]; then
    echo "== Build OK; committing local image ultrafusion-ros2:0.2.2-local ..."
    docker commit uf_build ultrafusion-ros2:0.2.2-local
    docker rm -f uf_build >/dev/null 2>&1 || true
    echo "Done. Use image 'ultrafusion-ros2:0.2.2-local' for runs."
else
    echo "== Build FAILED (exit ${CODE}); keeping container uf_build for inspection." >&2
    exit 1
fi
