#!/usr/bin/env bash
#
# Probe download sources used by Ultra-Fusion reproduction.
# Prints direct (no-proxy) and proxy HTTP codes for each endpoint.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

URLS=(
    "https://github.com"
    "https://raw.githubusercontent.com"
    "https://registry-1.docker.io/v2/"
    "https://registry.cn-hangzhou.aliyuncs.com/v2/"
    "https://huggingface.co"
    "https://onedrive.live.com"
    "https://www.alipan.com"
    "http://47.100.60.229:8088/"
    "https://objects.githubusercontent.com"
)

probe() {
    local url="$1"
    local direct proxy
    direct="$(curl --noproxy '*' -sL --connect-timeout 6 -o /dev/null -w '%{http_code}' "${url}" 2>/dev/null)"
    proxy="$(curl -sL --connect-timeout 6 -o /dev/null -w '%{http_code}' "${url}" 2>/dev/null)"
    printf '%-48s direct=%-4s proxy=%-4s\n' "${url}" "${direct:-ERR}" "${proxy:-ERR}"
}

echo "== Download source reachability (direct vs proxy) =="
for url in "${URLS[@]}"; do
    probe "${url}"
done
