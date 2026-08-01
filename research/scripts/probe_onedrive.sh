#!/usr/bin/env bash
#
# Diagnose OneDrive share link download options for the M3DGR bag.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

SHARE_URL="https://1drv.ms/u/c/2b4bfc0edf421186/EYYRQt8O_EsggCv0DwAAAAAB-86r95z48cuIi_MTyIoq8A?e=IiMGzk"

echo "== 1. Last HTTP response body from &download=1 =="
curl -sL --connect-timeout 10 "${SHARE_URL}&download=1" | head -c 1500
echo

echo
echo "== 2. api.onedrive.com share endpoint =="
B64="$(printf '%s' "${SHARE_URL}" | base64 -w0 | tr '+/' '-_' | tr -d '=')"
API_URL="https://api.onedrive.com/v1.0/shares/u!${B64}/root/content"
curl -sIL --connect-timeout 10 -o /dev/null \
    -w 'code=%{http_code} type=%{content_type} len=%{content_length} final=%{url_effective}\n' \
    "${API_URL}"
