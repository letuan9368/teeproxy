#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="${SCRIPT_DIR}/Tee-Proxy-Core-v2.sh"
if [[ ! -f "${CORE}" ]]; then
  echo "[*] Tai Tee-Proxy-Core-v2.sh tu GitHub..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Core-v2.sh" -o "${CORE}"
  else
    wget -qO "${CORE}" "https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Core-v2.sh"
  fi
fi
# shellcheck source=/dev/null
source "${CORE}"

ensure_root
apply_system_tuning

echo "[*] Kernel/network tuning applied."
echo "[*] Verify:"
echo "    sysctl fs.file-max net.core.somaxconn net.ipv4.ip_local_port_range"
