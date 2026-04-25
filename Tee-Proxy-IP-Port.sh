#!/usr/bin/env bash
set -euo pipefail

COUNT="${1:-2000}"
FIRST_PORT="${2:-22000}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="${SCRIPT_DIR}/Tee-Proxy-Core-v2.sh"
if [[ ! -f "${CORE}" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Core-v2.sh" -o "${CORE}"
fi
source "${CORE}"

ensure_count_and_ports "${COUNT}" "${FIRST_PORT}" 4000
run_mode "http_ipport" "${COUNT}" "${FIRST_PORT}"
