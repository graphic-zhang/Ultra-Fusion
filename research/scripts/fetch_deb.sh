#!/usr/bin/env bash
#
# Download the Ultra-Fusion ROS2 .deb (v0.2.2) using the project's China
# mirror first (direct), falling back to GitHub Releases via proxy.
# Verifies the SHA256 checksum from the README.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

DEB="ultrafusion-ros2_0.2.2_amd64.deb"
SHA_EXPECTED="243f88fa5e3d87fcd96a2b02c8561fca4d5e56419ab72ec0a3a731b0ea34cccc"
OUT_DIR="${REPO_ROOT}/research/downloads"
mkdir -p "${OUT_DIR}"
OUT="${OUT_DIR}/${DEB}"

MIRROR_URL="http://47.100.60.229:8088/loc_map/releases/ultrafusion/${DEB}"
GITHUB_URL="https://github.com/sjtuyinjie/Ultra-Fusion/releases/download/v0.2.2/${DEB}"

echo "== Try mirror (direct) =="
curl --noproxy '*' -sL --connect-timeout 10 -o "${OUT}" "${MIRROR_URL}" || true
if [ "$(stat -c %s "${OUT}" 2>/dev/null || echo 0)" -lt 100000 ]; then
    echo "mirror returned invalid/short response; trying GitHub via proxy"
    rm -f "${OUT}"
    curl -sL --connect-timeout 10 -o "${OUT}" "${GITHUB_URL}"
fi

ls -la "${OUT}"
echo "== SHA256 verify =="
SHA_ACTUAL="$(sha256sum "${OUT}" | awk '{print $1}')"
echo "expected: ${SHA_EXPECTED}"
echo "actual:   ${SHA_ACTUAL}"
if [ "${SHA_ACTUAL}" = "${SHA_EXPECTED}" ]; then
    echo "SHA256 OK"
else
    echo "SHA256 MISMATCH"
    exit 1
fi
