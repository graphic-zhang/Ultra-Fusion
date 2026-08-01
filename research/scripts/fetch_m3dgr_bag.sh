#!/usr/bin/env bash
#
# Download the M3DGR Occlusion01 rosbag (smallest sequence, ~1.46 GB).
# OneDrive is blocked when accessed directly, so this goes through the proxy.
# Supports resume (-C -), so re-run to continue an interrupted download.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

# Occlusion01 rosbag (OneDrive, from the M3DGR sequence table)
URL="https://1drv.ms/u/c/2b4bfc0edf421186/EYYRQt8O_EsggCv0DwAAAAAB-86r95z48cuIi_MTyIoq8A?e=IiMGzk&download=1"

OUT_DIR="${REPO_ROOT}/research/downloads/data"
mkdir -p "${OUT_DIR}"
OUT="${OUT_DIR}/occlusion01.bag"

echo "== Probe (HEAD) =="
curl -sIL --connect-timeout 10 -o /dev/null \
    -w 'code=%{http_code} type=%{content_type} len=%{content_length}\n' "${URL}"

echo "== Download =="
curl -L --connect-timeout 15 -C - -o "${OUT}" "${URL}"

echo
echo "== Result =="
ls -la "${OUT}"
file "${OUT}"
