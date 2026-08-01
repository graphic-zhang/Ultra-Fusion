#!/usr/bin/env bash
#
# Fetch up-to-date info about Ultra-Fusion / M3DGR from the web.
# Run: bash research/scripts/fetch_info.sh
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

OUT="${REPO_ROOT}/research/notes"
mkdir -p "${OUT}"

echo "==> Releases (latest) ..."
curl -sL --connect-timeout 10 \
    https://api.github.com/repos/sjtuyinjie/Ultra-Fusion/releases/latest \
    -o /tmp/uf_releases.json
grep -E '"(tag_name|browser_download_url|name)"' /tmp/uf_releases.json \
    | head -20 > "${OUT}/releases.txt"
cat "${OUT}/releases.txt"

echo
echo "==> M3DGR dataset sequences (bag sizes) ..."
curl -sL --connect-timeout 10 \
    https://raw.githubusercontent.com/sjtuyinjie/M3DGR/main/README.md \
    -o /tmp/m3dgr_readme.md
grep -n -iE 'bag|\.zip|GB|sequence|google|onedrive|download' /tmp/m3dgr_readme.md \
    | head -40 > "${OUT}/m3dgr_sequences.txt"
cat "${OUT}/m3dgr_sequences.txt"

echo
echo "Notes written to ${OUT}/"
