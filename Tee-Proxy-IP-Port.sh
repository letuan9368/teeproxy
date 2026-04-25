#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash Tee-Proxy-IP-Port.sh [COUNT] [FIRST_PORT]
# Example:
#   bash Tee-Proxy-IP-Port.sh 2000 22000

MAX_PROXIES=2000
COUNT="${1:-2000}"
FIRST_PORT="${2:-22000}"

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || ! [[ "$FIRST_PORT" =~ ^[0-9]+$ ]]; then
  echo "COUNT và FIRST_PORT phải là số nguyên dương."
  exit 1
fi

if (( COUNT < 1 )); then
  echo "COUNT phải >= 1."
  exit 1
fi

if (( COUNT > MAX_PROXIES )); then
  echo "COUNT vượt quá giới hạn. Tối đa: ${MAX_PROXIES}."
  exit 1
fi

LAST_PORT=$((FIRST_PORT + COUNT - 1))
if (( LAST_PORT > 65535 )); then
  echo "Dải port không hợp lệ: ${FIRST_PORT}-${LAST_PORT} (>65535)."
  exit 1
fi

WORKDIR="/home/bkns"
WORKDATA="${WORKDIR}/data_ip_port.txt"
PROXY_BIN="/usr/local/etc/3proxy/bin/3proxy"
PROXY_CFG="/usr/local/etc/3proxy/3proxy-ip-port.cfg"
PROXY_SERVICE="/etc/systemd/system/3proxy-ip-port.service"

hex4() {
  printf "%04x" "$((RANDOM % 65536))"
}

gen_ipv6() {
  local prefix="$1"
  echo "${prefix}:$(hex4):$(hex4):$(hex4):$(hex4)"
}

detect_interface() {
  ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

install_deps() {
  dnf -y install epel-release >/dev/null 2>&1 || true
  dnf -y install gcc make wget tar curl iproute >/dev/null
}

install_3proxy() {
  if [[ -x "${PROXY_BIN}" ]]; then
    echo "[*] 3proxy already exists, skip build."
    return
  fi

  echo "[*] Installing 3proxy 0.8.13..."
  local build_dir="/root/3proxy-0.8.13"
  local url="https://github.com/z3APA3A/3proxy/archive/refs/tags/0.8.13.tar.gz"

  rm -rf /root/3proxy-0.8.13 /root/3proxy-0.8.13.tar.gz
  wget -qO /root/3proxy-0.8.13.tar.gz "$url"
  tar -xzf /root/3proxy-0.8.13.tar.gz -C /root

  cd "$build_dir"
  make -f Makefile.Linux
  mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
  install -m 755 src/3proxy "$PROXY_BIN"
  cd /root
}

gen_data() {
  local ip4="$1"
  local ip6_prefix="$2"
  : > "$WORKDATA"
  for ((port=FIRST_PORT; port<=LAST_PORT; port++)); do
    echo "${ip4}/${port}/$(gen_ipv6 "$ip6_prefix")" >> "$WORKDATA"
  done
}

gen_if_script() {
  local iface="$1"
  cat > "${WORKDIR}/boot_ifconfig_ip_port.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
while IFS='/' read -r _ip4 _port ipv6; do
  ip -6 addr add "\${ipv6}/64" dev "${iface}" 2>/dev/null || true
done < "${WORKDATA}"
EOF
  chmod +x "${WORKDIR}/boot_ifconfig_ip_port.sh"
}

gen_3proxy_cfg() {
  {
    cat <<EOF
daemon
maxconn 4000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2606:4700:4700::1111
nserver 2001:4860:4860::8888
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
auth none
allow *

EOF
    awk -F "/" '{
      print "proxy -6 -n -a -p" $2 " -i" $1 " -e" $3
      print "flush"
      print ""
    }' "${WORKDATA}"
  } > "${PROXY_CFG}"
}

gen_proxy_list() {
  awk -F "/" '{print $1 ":" $2}' "${WORKDATA}" > "${WORKDIR}/proxy_ip_port.txt"
}

create_systemd_service() {
  cat > "${PROXY_SERVICE}" <<EOF
[Unit]
Description=3proxy IP:PORT service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/bin/bash ${WORKDIR}/boot_ifconfig_ip_port.sh
ExecStart=${PROXY_BIN} ${PROXY_CFG}
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
}

cleanup_old_state() {
  local iface="$1"
  echo "[*] Cleaning old IP:PORT proxy state..."

  systemctl stop 3proxy-ip-port >/dev/null 2>&1 || true

  if [[ -f "${WORKDATA}" ]]; then
    while IFS='/' read -r _ip4 _port ipv6; do
      ip -6 addr del "${ipv6}/64" dev "${iface}" 2>/dev/null || true
    done < "${WORKDATA}"
  fi

  rm -f "${WORKDATA}" \
        "${WORKDIR}/proxy_ip_port.txt" \
        "${WORKDIR}/boot_ifconfig_ip_port.sh" \
        "${PROXY_CFG}"
}

main() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Hãy chạy script bằng root."
    exit 1
  fi

  mkdir -p "$WORKDIR"

  echo "[*] Installing dependencies..."
  install_deps
  install_3proxy

  local ip4 ip6_raw ip6_prefix iface
  ip4="$(curl -4 -s icanhazip.com || true)"
  ip6_raw="$(curl -6 -s icanhazip.com || true)"
  ip6_prefix="$(echo "${ip6_raw}" | awk -F: '{print $1":"$2":"$3":"$4}')"
  iface="$(detect_interface)"

  if [[ -z "${ip4}" || -z "${ip6_prefix}" || -z "${iface}" ]]; then
    echo "Không lấy được IP/interface. Kiểm tra IPv4/IPv6 và network."
    exit 1
  fi

  echo "[*] IPv4: ${ip4}"
  echo "[*] IPv6 prefix: ${ip6_prefix}"
  echo "[*] Interface: ${iface}"
  echo "[*] Ports: ${FIRST_PORT}-${LAST_PORT} (${COUNT} proxies)"

  cleanup_old_state "${iface}"
  gen_data "${ip4}" "${ip6_prefix}"
  gen_if_script "${iface}"
  gen_3proxy_cfg
  gen_proxy_list
  create_systemd_service

  echo "[*] Restarting 3proxy-ip-port..."
  systemctl daemon-reload
  systemctl enable --now 3proxy-ip-port

  echo "[*] Done."
  echo "[*] Proxy list: ${WORKDIR}/proxy_ip_port.txt"
  echo "[*] Total proxies: $(wc -l < "${WORKDIR}/proxy_ip_port.txt")"
}

main "$@"
