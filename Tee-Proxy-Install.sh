#!/usr/bin/env bash
set -euo pipefail

# Cài bộ script TeeProxy lên VPS từ thư mục local (không cần wget/GitHub).
# Chạy trên VPS AlmaLinux 8/9 sau khi upload thư mục Bash proxy.

INSTALL_DIR="${1:-/root/teeproxy}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Hãy chạy bằng root: bash Tee-Proxy-Install.sh"
  exit 1
fi

mkdir -p "${INSTALL_DIR}"
cp -f "${SOURCE_DIR}"/*.sh "${INSTALL_DIR}/"
chmod +x "${INSTALL_DIR}"/*.sh

echo "[*] Đã cài vào: ${INSTALL_DIR}"
echo "[*] File chính:"
ls -1 "${INSTALL_DIR}"/Tee-Proxy-*.sh "${INSTALL_DIR}"/teeproxy_load_core.sh 2>/dev/null || true
echo
echo "Ví dụ chạy HTTP IP:PORT (2000 proxy, port 22000):"
echo "  cd ${INSTALL_DIR} && bash Tee-Proxy-IP-Port.sh"
echo
echo "Ví dụ IPv4-only (VPS không có IPv6):"
echo "  cd ${INSTALL_DIR} && TEEPROXY_IP_MODE=ipv4 bash Tee-Proxy-IP-Port.sh"
echo
echo "Kiểm tra sau khi chạy:"
echo "  systemctl is-active 3proxy-ip-port"
echo "  head ${INSTALL_DIR%/teeproxy}/../bkns/proxy_ip_port.txt 2>/dev/null || head /home/bkns/proxy_ip_port.txt"
