#!/usr/bin/env bash
#
# Install Docker Engine (docker.io) inside WSL2 for Ultra-Fusion reproduction.
#
# Run with sudo (you will be prompted for your password once):
#   sudo bash research/scripts/setup_docker.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/proxy_env.sh"

export DEBIAN_FRONTEND=noninteractive

echo "==> apt update + install docker.io ..."
apt-get update
apt-get install -y docker.io

USER_NAME="$(stat -c '%U' "${REPO_ROOT}" 2>/dev/null || echo graphic)"
echo "==> Add user '${USER_NAME}' to the docker group ..."
usermod -aG docker "${USER_NAME}"

echo "==> Enable Docker daemon (systemd) ..."
systemctl enable --now docker

echo "==> Configure Docker daemon to pull images through the proxy ..."
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://${PROXY_HOST}:${PROXY_PORT}"
Environment="HTTPS_PROXY=http://${PROXY_HOST}:${PROXY_PORT}"
Environment="NO_PROXY=localhost,127.0.0.1,172.16.0.0/12,192.168.0.0/16,10.0.0.0/8"
EOF
systemctl daemon-reload
systemctl restart docker

echo "==> Verify ..."
docker info | grep -E 'Server Version|Storage Driver|Operating System' || true

echo
echo "Docker installed. For the docker group to take effect, either:"
echo "  - log out of WSL and open a new terminal, or"
echo "  - run: newgrp docker"
echo "Next: I will pull the Ultra-Fusion ROS2 image and set up the runtime."
