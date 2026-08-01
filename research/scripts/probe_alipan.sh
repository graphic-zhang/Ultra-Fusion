#!/usr/bin/env bash
#
# Raw probe of the Alipan public share API (for debugging fetch_alipan.py).
#
set -uo pipefail

SHARE_ID="${1:-r3P6Bcxj7Tu}"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
CANARY="client=web,app=share,version=v2.3.1"

echo "== get_share_token =="
TOKEN_JSON="$(curl -sS -X POST https://api.alipan.com/v2/share_link/get_share_token \
    -H "Content-Type: application/json" \
    -H "User-Agent: ${UA}" \
    -H "X-Canary: ${CANARY}" \
    -H "Referer: https://www.alipan.com/" \
    -d "{\"share_id\":\"${SHARE_ID}\"}")"
echo "${TOKEN_JSON}" | head -c 600
echo

TOKEN="$(printf '%s' "${TOKEN_JSON}" | sed -n 's/.*"share_token":"\([^"]*\)".*/\1/p')"
echo "share_token=${TOKEN:0:12}..."

echo
echo "== list_by_share (token in header) =="
curl -sS -X POST https://api.alipan.com/v2/file/list_by_share \
    -H "Content-Type: application/json" \
    -H "User-Agent: ${UA}" \
    -H "X-Canary: ${CANARY}" \
    -H "X-Share-Token: ${TOKEN}" \
    -H "Referer: https://www.alipan.com/" \
    -d "{\"share_id\":\"${SHARE_ID}\",\"parent_file_id\":\"root\",\"limit\":100,\"order_by\":\"name\",\"order_direction\":\"ASC\"}" \
    | head -c 1000
echo
