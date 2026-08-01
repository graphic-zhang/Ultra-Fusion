#!/usr/bin/env bash
#
# Environment diagnostic for Ultra-Fusion reproduction on this machine.
# Run: bash research/scripts/env_check.sh
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "===== 1. WSL / Linux environment ====="
uname -a
grep -E "PRETTY_NAME" /etc/os-release
echo "CPU cores: $(nproc), Mem: $(free -h | awk '/Mem:/{print $2}')"
df -h / /mnt/e 2>/dev/null | head -3

echo
echo "===== 2. Toolchain ====="
echo "git: $(git --version 2>/dev/null || echo MISSING)"
echo "python3: $(python3 --version 2>/dev/null || echo MISSING)"
echo "docker: $(docker --version 2>/dev/null || echo MISSING)"
echo "gh: $(gh --version 2>/dev/null | head -1 || echo MISSING)"
echo "ros2: $(ls /opt/ros 2>/dev/null || echo 'not installed')"

echo
echo "===== 3. Proxy & GitHub connectivity ====="
if [ -f "${REPO_ROOT}/research/scripts/proxy_env.sh" ]; then
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/research/scripts/proxy_env.sh"
fi
echo "http_proxy=${http_proxy:-unset}"
code="$(curl -sL --connect-timeout 8 -o /dev/null -w '%{http_code}' https://github.com 2>/dev/null)"
echo "github.com -> HTTP ${code:-FAILED}"
code2="$(curl -sL --connect-timeout 8 -o /dev/null -w '%{http_code}' https://www.google.com 2>/dev/null)"
echo "google.com -> HTTP ${code2:-FAILED}"

echo
echo "===== 4. SSH to GitHub ====="
if [ -f ~/.ssh/id_ed25519.pub ]; then
    echo "Public key: $(cat ~/.ssh/id_ed25519.pub)"
else
    echo "No id_ed25519 key found."
fi
if command -v nc >/dev/null 2>&1; then
    ssh -o ProxyCommand="nc -X 5 -x ${PROXY_HOST:-127.0.0.1}:${PROXY_PORT:-7897} %h %p" \
        -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1 | head -2
else
    echo "nc (netcat-openbsd) not installed; cannot test SSH through proxy."
fi

echo
echo "===== 5. Git repo ====="
cd "${REPO_ROOT}" || exit 1
git remote -v
git log --oneline -1
