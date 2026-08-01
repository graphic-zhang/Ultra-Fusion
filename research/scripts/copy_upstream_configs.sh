#!/usr/bin/env bash
#
# Copy the upstream M3DGR LVWIO profile + camera calib out of the runtime
# image into research/configs/ so we can make a research variant.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT="${REPO_ROOT}/research/configs"
mkdir -p "${OUT}"

docker run --rm -v "${OUT}:/out" ultrafusion-ros2:0.2.2-local bash -c 'cp /opt/ultrafusion/config/m3dgr/uf_m3dgr_ros2_lvwio.yaml /out/ && cp /opt/ultrafusion/config/m3dgr/color.yaml /out/'

ls -la "${OUT}"
