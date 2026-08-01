#!/usr/bin/env bash
#
# Inspect available Ultra-Fusion Docker images on Alibaba ACR and Docker Hub.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

echo "== ACR: bit_robot_image/ultrafusion-ros2 tags (direct) =="
curl --noproxy '*' -sL --connect-timeout 8 \
    "https://registry.cn-hangzhou.aliyuncs.com/v2/bit_robot_image/ultrafusion-ros2/tags/list" \
    | head -c 1200
echo

echo "== ACR: bit_robot_image/ultrafusion tags (direct) =="
curl --noproxy '*' -sL --connect-timeout 8 \
    "https://registry.cn-hangzhou.aliyuncs.com/v2/bit_robot_image/ultrafusion/tags/list" \
    | head -c 1200
echo

echo "== Docker Hub: maotiandocker/ultrafusion-ros2 tags (proxy) =="
curl -sL --connect-timeout 8 \
    "https://hub.docker.com/v2/repositories/maotiandocker/ultrafusion-ros2/tags?page_size=20" \
    | grep -oE '"name":"[^"]+"' | head -20

echo "== Docker Hub: maotiandocker/ultrafusion tags (proxy) =="
curl -sL --connect-timeout 8 \
    "https://hub.docker.com/v2/repositories/maotiandocker/ultrafusion/tags?page_size=20" \
    | grep -oE '"name":"[^"]+"' | head -20
