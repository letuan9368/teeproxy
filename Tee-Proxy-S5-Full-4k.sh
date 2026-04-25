#!/usr/bin/env bash
set -euo pipefail

COUNT="${1:-4000}"
FIRST_PORT_PASS="${2:-32000}"
FIRST_PORT_IP_PORT="${3:-37000}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="${SCRIPT_DIR}/Tee-Proxy-Core-v2.sh"
if [[ ! -f "${CORE}" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Core-v2.sh" -o "${CORE}"
fi
source "${CORE}"

ensure_count_and_ports "${COUNT}" "${FIRST_PORT_PASS}" 4000 "${FIRST_PORT_IP_PORT}"
run_mode "socks5_full4k" "${COUNT}" "${FIRST_PORT_PASS}" "${FIRST_PORT_IP_PORT}"
