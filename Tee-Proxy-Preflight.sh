#!/usr/bin/env bash
set -euo pipefail

echo "=== TeeProxy Preflight ==="

ok=1

echo "[1] Public IPv4"
ipv4="$(curl -4 -s --max-time 8 https://api.ipify.org || true)"
if [[ -n "${ipv4}" ]]; then
  echo "  OK: ${ipv4}"
else
  echo "  FAIL: Khong lay duoc IPv4 outbound"
  ok=0
fi

echo "[2] Public IPv6"
ipv6="$(curl -6 -s --max-time 8 https://api64.ipify.org || true)"
if [[ -n "${ipv6}" ]]; then
  echo "  OK: ${ipv6}"
else
  echo "  FAIL: Khong lay duoc IPv6 outbound"
  ok=0
fi

echo "[3] Interface va default route"
ip -4 route | sed -n '1,3p' || true
ip -6 route | sed -n '1,5p' || true

echo "[4] Kernel flags lien quan"
sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null || true
sysctl net.ipv6.ip_nonlocal_bind 2>/dev/null || true

if [[ "${ok}" -eq 1 ]]; then
  echo "RESULT: READY (co IPv4 + IPv6 outbound)"
  exit 0
else
  echo "RESULT: NOT_READY (thieu outbound IPv4/IPv6)"
  exit 2
fi
