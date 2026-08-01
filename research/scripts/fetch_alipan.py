#!/usr/bin/env python3
"""
Fetch M3DGR rosbag files from an Alipan (阿里云盘) public share link.

Uses the same public share API as alist; no login required.
Usage:
  python3 fetch_alipan.py list <share_id>            # list files
  python3 fetch_alipan.py url  <share_id> <file_id>  # print download URL
"""

import json
import sys
import urllib.request
import urllib.error

API = "https://api.alipan.com/v2"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Content-Type": "application/json",
    "X-Canary": "client=web,app=share,version=v2.3.1",
    "Referer": "https://www.alipan.com/",
}


def post(path: str, payload: dict, extra_headers: dict | None = None):
    hdrs = dict(HEADERS)
    if extra_headers:
        hdrs.update(extra_headers)
    req = urllib.request.Request(
        API + path,
        data=json.dumps(payload).encode(),
        headers=hdrs,
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors="replace")
        print(f"HTTP {exc.code} {path}: {body[:500]}", file=sys.stderr)
        raise


def get_share_token(share_id: str) -> str:
    r = post("/share_link/get_share_token", {"share_id": share_id})
    token = r.get("share_token")
    if not token:
        raise RuntimeError(f"no share_token: {r}")
    return token


def list_share(share_id: str, token: str, parent: str = "root", limit: int = 200):
    r = post(
        "/file/list_by_share",
        {
            "share_id": share_id,
            "parent_file_id": parent,
            "limit": limit,
            "order_by": "name",
            "order_direction": "ASC",
        },
        extra_headers={"X-Share-Token": token},
    )
    return r.get("items", []), r.get("next_marker")


def get_download_url(share_id: str, token: str, file_id: str) -> str:
    r = post(
        "/file/get_share_link_download_url",
        {"share_id": share_id, "file_id": file_id},
        extra_headers={"X-Share-Token": token},
    )
    url = r.get("download_url")
    if not url:
        raise RuntimeError(f"no download_url: {r}")
    return url


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    cmd, share_id = sys.argv[1], sys.argv[2]
    token = get_share_token(share_id)
    if cmd == "list":
        items, _ = list_share(share_id, token)
        for it in items:
            print(
                f"{it.get('type'):8s} {it.get('size', 0):>12d}  "
                f"{it.get('file_id'):<60s} {it.get('name')}"
            )
    elif cmd == "url":
        file_id = sys.argv[3]
        print(get_download_url(share_id, token, file_id))
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
