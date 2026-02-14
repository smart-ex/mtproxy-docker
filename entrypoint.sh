#!/bin/sh
set -e

# Download Telegram proxy config files (recommended to update daily via container restart)
echo "[*] Downloading proxy-secret and proxy-multi.conf..."
curl -sf https://core.telegram.org/getProxySecret -o /data/proxy-secret
curl -sf https://core.telegram.org/getProxyConfig -o /data/proxy-multi.conf

if [ ! -s /data/proxy-secret ] || [ ! -s /data/proxy-multi.conf ]; then
    echo "[!] Failed to download Telegram config files. Check network connectivity."
    exit 1
fi

# SECRET is required (32 hex chars, e.g. from: head -c 16 /dev/urandom | xxd -ps)
if [ -z "${SECRET}" ]; then
    echo "[!] SECRET environment variable is required."
    echo "    Generate one with: head -c 16 /dev/urandom | xxd -ps"
    exit 1
fi

HOST_PORT="${HOST_PORT:-443}"
STATS_PORT="${STATS_PORT:-8888}"
WORKERS="${WORKERS:-1}"

# Build mtproto-proxy arguments (use set/exec to avoid word-splitting and injection)
set -- -u nobody -p "${STATS_PORT}" -H "${HOST_PORT}" -S "${SECRET}" \
    --aes-pwd /data/proxy-secret /data/proxy-multi.conf -M "${WORKERS}"
[ -n "${PROXY_TAG}" ] && set -- "$@" -P "${PROXY_TAG}"
# Required when behind NAT (e.g. cloud Floating IP): proxy must advertise external IP to clients
# MTProxy matches local_ip exactly; in Docker that is the container's bridge IP (e.g. 172.18.0.2), not 0.0.0.0
if [ -n "${EXTERNAL_IP}" ]; then
  CONTAINER_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/{print $7;exit}')"
  if [ -n "${CONTAINER_IP}" ]; then
    set -- "$@" --nat-info "${CONTAINER_IP}:${EXTERNAL_IP}"
    echo "[*] NAT: advertising ${EXTERNAL_IP} for local ${CONTAINER_IP}"
  else
    echo "[!] EXTERNAL_IP set but could not detect container IP; NAT may not work"
    set -- "$@" --nat-info "0.0.0.0:${EXTERNAL_IP}"
  fi
fi

echo "[*] Starting mtproto-proxy on port ${HOST_PORT}..."
exec mtproto-proxy "$@"
