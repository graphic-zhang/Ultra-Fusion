#!/usr/bin/env bash
#
# Wire this local clone to YOUR GitHub account (fork + SSH push).
#
# Before running:
#   1. Add your SSH public key to GitHub:
#      Settings -> SSH and GPG keys -> New SSH key
#      (key is printed below / stored at ~/.ssh/id_ed25519.pub)
#   2. Fork https://github.com/sjtuyinjie/Ultra-Fusion on GitHub.
#
# Usage:
#   bash research/scripts/github_setup.sh <your-github-username>
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

GITHUB_USER="${1:-}"
if [ -z "${GITHUB_USER}" ]; then
    echo "Usage: bash research/scripts/github_setup.sh <your-github-username>" >&2
    exit 1
fi

echo "==> Your SSH public key (add this to GitHub):"
cat ~/.ssh/id_ed25519.pub
echo

echo "==> Configure ~/.ssh/config so SSH to GitHub goes through the Clash proxy:"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
    cat >> ~/.ssh/config <<EOF

Host github.com
    HostName github.com
    User git
    ProxyCommand nc -X 5 -x 127.0.0.1:7897 %h %p
    StrictHostKeyChecking accept-new
EOF
    chmod 600 ~/.ssh/config
    echo "~/.ssh/config updated."
else
    echo "~/.ssh/config already contains github.com host."
fi

echo
echo "==> Verify SSH authentication (must print 'Hi <user>!'):"
ssh -o ConnectTimeout=10 -T git@github.com 2>&1 | head -3

echo
echo "==> Point this clone at your fork:"
cd "${REPO_ROOT}" || exit 1
git remote rename origin upstream 2>/dev/null || true
git remote add origin "git@github.com:${GITHUB_USER}/Ultra-Fusion.git" 2>/dev/null \
    || git remote set-url origin "git@github.com:${GITHUB_USER}/Ultra-Fusion.git"
git remote -v

echo
echo "==> Done. Workflow:"
echo "  git push origin main            # push your branch/notes to your fork"
echo "  git fetch upstream && git rebase upstream/main   # sync with upstream"
echo "  git push origin <branch>        # open a PR to upstream if you like"
