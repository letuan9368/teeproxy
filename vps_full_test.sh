#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

if [[ ! -f "${SCRIPT_DIR}/Tee-Proxy-Core-v2.sh" ]]; then
  echo "Thiếu Tee-Proxy-Core-v2.sh. Chạy script từ thư mục Bash proxy đã upload."
  exit 1
fi

chmod +x "${SCRIPT_DIR}"/*.sh

export TEEPROXY_IP_MODE=ipv4

bash Tee-Proxy-Optimize.sh
bash Tee-Proxy-Preflight.sh || true

echo "=== RUN HTTP PASS ==="
bash Tee-Proxy-Pass.sh 300 22000
hp="$(head -n1 /home/bkns/proxy.txt)"
hip="$(echo "$hp" | cut -d: -f1)"
hpo="$(echo "$hp" | cut -d: -f2)"
hus="$(echo "$hp" | cut -d: -f3)"
hpa="$(echo "$hp" | cut -d: -f4)"
hptest="$(curl -s -m 10 -x "http://${hip}:${hpo}" -U "${hus}:${hpa}" https://api.ipify.org || true)"
echo "HTTP_PASS_TEST:${hptest}"

echo "=== RUN HTTP NOAUTH ==="
bash Tee-Proxy-IP-Port.sh 300 23000
hn="$(head -n1 /home/bkns/proxy_ip_port.txt)"
hni="$(echo "$hn" | cut -d: -f1)"
hnp="$(echo "$hn" | cut -d: -f2)"
hntest="$(curl -s -m 10 -x "http://${hni}:${hnp}" https://api.ipify.org || true)"
echo "HTTP_NOAUTH_TEST:${hntest}"

echo "=== RUN SOCKS5 PASS ==="
bash Tee-Proxy-Socks5-Pass.sh 300 24000
sp="$(head -n1 /home/bkns/proxy_socks5_pass.txt)"
spi="$(echo "$sp" | cut -d: -f1)"
spp="$(echo "$sp" | cut -d: -f2)"
spu="$(echo "$sp" | cut -d: -f3)"
sps="$(echo "$sp" | cut -d: -f4)"
sptest="$(curl -s -m 10 --proxy "socks5h://${spu}:${sps}@${spi}:${spp}" https://api.ipify.org || true)"
echo "SOCKS5_PASS_TEST:${sptest}"

echo "=== RUN SOCKS5 NOAUTH ==="
bash Tee-Proxy-Socks5-IP-Port.sh 300 25000
sn="$(head -n1 /home/bkns/proxy_socks5_ip_port.txt)"
sni="$(echo "$sn" | cut -d: -f1)"
snp="$(echo "$sn" | cut -d: -f2)"
sntest="$(curl -s -m 10 --proxy "socks5h://${sni}:${snp}" https://api.ipify.org || true)"
echo "SOCKS5_NOAUTH_TEST:${sntest}"

echo "=== RUN HTTP FULL ==="
bash Tee-Proxy-Full-4k.sh 400 26000 27000

echo "=== RUN SOCKS5 FULL ==="
bash Tee-Proxy-S5-Full-4k.sh 400 28000 29000

echo "=== COUNTS ==="
wc -l /home/bkns/proxy.txt /home/bkns/proxy_ip_port.txt /home/bkns/proxy_socks5_pass.txt /home/bkns/proxy_socks5_ip_port.txt /home/bkns/proxy_full4k_pass.txt /home/bkns/proxy_full4k_ip_port.txt /home/bkns/proxy_s5_full4k_pass.txt /home/bkns/proxy_s5_full4k_ip_port.txt

echo "=== SERVICES ==="
systemctl is-active 3proxy-custom 3proxy-ip-port 3proxy-socks5-pass 3proxy-socks5-ip-port

echo "=== ROTATION TEST (HTTP PASS first proxy x3) ==="
r1="$(curl -s -m 10 -x "http://${hip}:${hpo}" -U "${hus}:${hpa}" https://api.ipify.org || true)"
r2="$(curl -s -m 10 -x "http://${hip}:${hpo}" -U "${hus}:${hpa}" https://api.ipify.org || true)"
r3="$(curl -s -m 10 -x "http://${hip}:${hpo}" -U "${hus}:${hpa}" https://api.ipify.org || true)"
echo "ROTATE_RESULT:${r1}|${r2}|${r3}"

echo "=== LISTEN SAMPLE ==="
ss -lntp | grep 3proxy | head -n 20
