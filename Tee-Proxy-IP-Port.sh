#!/usr/bin/env bash
set -euo pipefail

echo "[*] Tee-Proxy-IP-Port.sh (HTTP khong pass, output IP:PORT)"

COUNT="${1:-2000}"
FIRST_PORT="${2:-22000}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="${SCRIPT_DIR}/Tee-Proxy-Core-v2.sh"
CORE_URL="https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Core-v2.sh"

echo "[*] Tai Tee-Proxy-Core-v2.sh tu GitHub..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "${CORE_URL}" -o "${CORE}"
else
  wget -qO "${CORE}" "${CORE_URL}"
fi
chmod +x "${CORE}" 2>/dev/null || true

export TEEPROXY_IP_MODE="${TEEPROXY_IP_MODE:-ipv4}"
# shellcheck source=/dev/null
source "${CORE}"

ensure_count_and_ports "${COUNT}" "${FIRST_PORT}" 4000
run_mode "http_ipport" "${COUNT}" "${FIRST_PORT}"

echo ""
echo "=== XONG ==="
echo "File proxy: /home/bkns/proxy_ip_port.txt"
echo "Kiem tra:   wc -l /home/bkns/proxy_ip_port.txt && head -n 5 /home/bkns/proxy_ip_port.txt"
