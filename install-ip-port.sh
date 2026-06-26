#!/usr/bin/env bash
# Bootstrap: tai day du script + chay HTTP IP:PORT (khong pass).
# One-liner:
#   wget -qO- https://raw.githubusercontent.com/letuan9368/teeproxy/master/install-ip-port.sh | bash
set -euo pipefail

RAW="https://raw.githubusercontent.com/letuan9368/teeproxy/master"
DIR="${TEEPROXY_DIR:-/root}"

mkdir -p "${DIR}"
cd "${DIR}"

teeproxy_fetch() {
  local name="$1"
  echo "[*] Tai ${name}..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${RAW}/${name}" -o "${name}"
  else
    wget -qO "${name}" "${RAW}/${name}"
  fi
  chmod +x "${name}" 2>/dev/null || true
}

teeproxy_fetch "Tee-Proxy-Core-v2.sh"
teeproxy_fetch "Tee-Proxy-IP-Port.sh"

export TEEPROXY_IP_MODE="${TEEPROXY_IP_MODE:-ipv4}"
exec bash "${DIR}/Tee-Proxy-IP-Port.sh" "$@"
