#!/usr/bin/env bash
#
# Sourceable proxy helper for Ultra-Fusion research in WSL.
#
# Usage:
#   source research/scripts/proxy_env.sh          # proxy ON  (default)
#   source research/scripts/proxy_env.sh off      # proxy OFF
#
# Why this file exists:
#   ~/.bashrc returns early for non-interactive shells, so `bash -lc`
#   and scripts do NOT see proxy_on / the proxy variables. This helper
#   sets the same Clash proxy in any shell.
#
# WSL2 note: WSL2 uses NAT networking by default, so 127.0.0.1 does NOT
# reach the Windows host. The proxy host is auto-detected:
#   - WSL2 NAT  -> Windows host = default gateway IP (e.g. 172.x.x.x)
#   - WSL1/mirrored WSL2 -> 127.0.0.1
# You can still override manually: export PROXY_HOST=127.0.0.1
#

export PROXY_PORT="${PROXY_PORT:-7897}"

detect_proxy_host() {
    local gw host
    gw="$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}')"
    for host in "${gw:-}" "127.0.0.1"; do
        [ -n "${host}" ] || continue
        if timeout 1 bash -c "</dev/tcp/${host}/${PROXY_PORT}" 2>/dev/null; then
            printf '%s' "${host}"
            return 0
        fi
    done
    printf '%s' "${gw:-127.0.0.1}"
}

export PROXY_HOST="${PROXY_HOST:-$(detect_proxy_host)}"
unset -f detect_proxy_host

_proxy_base="http://${PROXY_HOST}:${PROXY_PORT}"
_proxy_socks="socks5://${PROXY_HOST}:${PROXY_PORT}"

if [ "${1:-on}" = "off" ]; then
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
    echo "Proxy OFF"
else
    export http_proxy="${_proxy_base}"
    export https_proxy="${_proxy_base}"
    export HTTP_PROXY="${_proxy_base}"
    export HTTPS_PROXY="${_proxy_base}"
    export all_proxy="${_proxy_socks}"
    export ALL_PROXY="${_proxy_socks}"
    export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8"
    export NO_PROXY="localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8"
    echo "Proxy ON -> ${_proxy_base} (socks ${_proxy_socks})"
fi

unset _proxy_base _proxy_socks
