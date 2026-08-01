#!/usr/bin/env python3
"""
Fix WSL proxy configuration after the WSL1 -> WSL2 conversion.

WSL2 uses NAT networking by default, so 127.0.0.1 no longer reaches the
Windows-host Clash proxy. This script makes three things auto-detect the
Windows host IP (default gateway):

  1. ~/.bashrc  -> PROXY_HOST (used by proxy_on / proxy_off)
  2. ~/.ssh/config -> ProxyCommand calls a wrapper that resolves the host
  3. ~/.ssh/ssh_proxy.sh -> new wrapper (created here)

Run:  python3 research/scripts/fix_wsl_proxy.py
"""

from __future__ import annotations

import pathlib
import re

HOME = pathlib.Path("/home/graphic")

# 1) ~/.bashrc -----------------------------------------------------------
bashrc = HOME / ".bashrc"
s = bashrc.read_text()
old = 'export PROXY_HOST="127.0.0.1"'
new = """# Auto-detect proxy host (WSL2 NAT -> Windows gateway; WSL1 -> 127.0.0.1)
if ! grep -qi microsoft-standard-WSL2 /proc/version 2>/dev/null; then
    export PROXY_HOST="127.0.0.1"
else
    export PROXY_HOST="$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}')"
    [ -n "$PROXY_HOST" ] || export PROXY_HOST="127.0.0.1"
fi"""
if old in s:
    bashrc.write_text(s.replace(old, new, 1))
    print("bashrc: patched PROXY_HOST auto-detection")
else:
    print("bashrc: pattern not found (skipped)")

# 2) ~/.ssh/ssh_proxy.sh -------------------------------------------------
ssh_dir = HOME / ".ssh"
ssh_dir.mkdir(mode=0o700, exist_ok=True)
proxy_sh = ssh_dir / "ssh_proxy.sh"
proxy_sh.write_text(
    """#!/usr/bin/env bash
# Route SSH through the Clash proxy on the Windows host (auto-detect WSL2 gateway).
HOST_IP="$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}')"
PROXY_HOST="${PROXY_HOST:-${HOST_IP:-127.0.0.1}}"
PROXY_PORT="${PROXY_PORT:-7897}"
exec nc -X 5 -x "${PROXY_HOST}:${PROXY_PORT}" "$1" "$2"
"""
)
proxy_sh.chmod(0o700)
print("ssh_proxy.sh: written")

# 3) ~/.ssh/config -------------------------------------------------------
cfg = ssh_dir / "config"
existing = cfg.read_text() if cfg.exists() else ""
clean = re.sub(r"\nHost github\.com\n(?:    .*\n)+", "", "\n" + existing + "\n")
block = """Host github.com
    HostName github.com
    User git
    ProxyCommand /home/graphic/.ssh/ssh_proxy.sh %h %p
    StrictHostKeyChecking accept-new
"""
cfg.write_text(clean.strip("\n") + "\n\n" + block)
cfg.chmod(0o600)
print("ssh config: github.com ProxyCommand updated")
