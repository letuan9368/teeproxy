#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Tee-Proxy-Core-v2.sh"

ensure_root
apply_system_tuning

echo "[*] Kernel/network tuning applied."
echo "[*] Verify:"
echo "    sysctl fs.file-max net.core.somaxconn net.ipv4.ip_local_port_range"
