#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash Tee-Proxy-Check.sh [LIST_FILE] [SAMPLE]
# Example:
#   bash Tee-Proxy-Check.sh /home/bkns/proxy.txt 20

LIST_FILE="${1:-/home/bkns/proxy.txt}"
SAMPLE="${2:-20}"

if ! [[ -f "${LIST_FILE}" ]]; then
  echo "Không tìm thấy file: ${LIST_FILE}"
  exit 1
fi

if ! [[ "${SAMPLE}" =~ ^[0-9]+$ ]] || (( SAMPLE < 1 )); then
  echo "SAMPLE phải là số nguyên dương."
  exit 1
fi

echo "[*] Checking ${SAMPLE} entries from ${LIST_FILE}"

ok=0
fail=0

while IFS= read -r line; do
  # HTTP auth: ip:port:user:pass
  if [[ "${line}" == *:*:*:* ]]; then
    ip="$(echo "${line}" | awk -F: '{print $1}')"
    port="$(echo "${line}" | awk -F: '{print $2}')"
    user="$(echo "${line}" | awk -F: '{print $3}')"
    pass="$(echo "${line}" | awk -F: '{print $4}')"
    if curl -x "http://${ip}:${port}" -U "${user}:${pass}" -m 8 -s https://api64.ipify.org >/dev/null; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
    fi
  else
    # IP:PORT (HTTP or SOCKS5 no-auth)
    ip="$(echo "${line}" | awk -F: '{print $1}')"
    port="$(echo "${line}" | awk -F: '{print $2}')"
    if curl -x "http://${ip}:${port}" -m 8 -s https://api64.ipify.org >/dev/null || \
       curl --socks5-hostname "${ip}:${port}" -m 8 -s https://api64.ipify.org >/dev/null; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
    fi
  fi
done < <(head -n "${SAMPLE}" "${LIST_FILE}")

echo "[*] OK: ${ok}"
echo "[*] FAIL: ${fail}"
