#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash Tee-Proxy-Full-4k.sh [COUNT] [FIRST_PORT_PASS] [FIRST_PORT_IP_PORT]
# Example:
#   bash Tee-Proxy-Full-4k.sh 4000 22000 27000

MAX_PROXIES=4000
COUNT="${1:-4000}"
FIRST_PORT_PASS="${2:-22000}"
FIRST_PORT_IP_PORT="${3:-27000}"

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || ! [[ "$FIRST_PORT_PASS" =~ ^[0-9]+$ ]] || ! [[ "$FIRST_PORT_IP_PORT" =~ ^[0-9]+$ ]]; then
  echo "COUNT và PORT phải là số nguyên dương."
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

LAST_PORT_PASS=$((FIRST_PORT_PASS + COUNT - 1))
LAST_PORT_IP_PORT=$((FIRST_PORT_IP_PORT + COUNT - 1))

if (( LAST_PORT_PASS > 65535 || LAST_PORT_IP_PORT > 65535 )); then
  echo "Dải port không hợp lệ (>65535)."
  exit 1
fi

if (( FIRST_PORT_PASS <= LAST_PORT_IP_PORT && FIRST_PORT_IP_PORT <= LAST_PORT_PASS )); then
  echo "2 dải port đang bị trùng nhau. Hãy đổi FIRST_PORT."
  exit 1
fi

WORKDIR="/home/bkns"
WORKDATA_PASS="${WORKDIR}/data_full4k_pass.txt"
WORKDATA_IP_PORT="${WORKDIR}/data_full4k_ip_port.txt"
BOOT_SCRIPT="${WORKDIR}/boot_ifconfig_full4k.sh"

PROXY_BIN="/usr/local/etc/3proxy/bin/3proxy"
PROXY_CFG_PASS="/usr/local/etc/3proxy/3proxy-full4k-pass.cfg"
PROXY_CFG_IP_PORT="/usr/local/etc/3proxy/3proxy-full4k-ip-port.cfg"

SERVICE_PASS="/etc/systemd/system/3proxy-full4k-pass.service"
SERVICE_IP_PORT="/etc/systemd/system/3proxy-full4k-ip-port.service"

random_pass() {
  tr </dev/urandom -dc 'A-Za-z0-9' | head -c8
  echo
}

random_5_digits() {
  tr </dev/urandom -dc '0-9' | head -c5
  echo
}

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
  dnf -y install gcc make wget tar curl iproute --nobest --skip-broken >/dev/null
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

gen_data_pass() {
  local ip4="$1"
  local ip6_prefix="$2"
  local username suffix
  declare -A used_users=()
  : > "$WORKDATA_PASS"
  for ((port=FIRST_PORT_PASS; port<=LAST_PORT_PASS; port++)); do
    while true; do
      suffix="$(random_5_digits)"
      username="teeblack${suffix}"
      [[ -z "${used_users[$username]+x}" ]] && break
    done
    used_users["$username"]=1
    echo "${username}/$(random_pass)/${ip4}/${port}/$(gen_ipv6 "$ip6_prefix")" >> "$WORKDATA_PASS"
  done
}

gen_data_ip_port() {
  local ip4="$1"
  local ip6_prefix="$2"
  : > "$WORKDATA_IP_PORT"
  for ((port=FIRST_PORT_IP_PORT; port<=LAST_PORT_IP_PORT; port++)); do
    echo "${ip4}/${port}/$(gen_ipv6 "$ip6_prefix")" >> "$WORKDATA_IP_PORT"
  done
}

gen_if_script() {
  local iface="$1"
  cat > "${BOOT_SCRIPT}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ -f "${WORKDATA_PASS}" ]]; then
  while IFS='/' read -r _user _pass _ip4 _port ipv6; do
    ip -6 addr add "\${ipv6}/64" dev "${iface}" 2>/dev/null || true
  done < "${WORKDATA_PASS}"
fi
if [[ -f "${WORKDATA_IP_PORT}" ]]; then
  while IFS='/' read -r _ip4 _port ipv6; do
    ip -6 addr add "\${ipv6}/64" dev "${iface}" 2>/dev/null || true
  done < "${WORKDATA_IP_PORT}"
fi
EOF
  chmod +x "${BOOT_SCRIPT}"
}

gen_cfg_pass() {
  {
    cat <<EOF
daemon
maxconn 12000
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
auth strong

users $(awk -F "/" 'BEGIN{ORS=""} {print $1 ":CL:" $2 " "}' "${WORKDATA_PASS}")

EOF
    awk -F "/" '{
      print "auth strong"
      print "allow " $1
      print "proxy -6 -n -a -p" $4 " -i" $3 " -e" $5
      print "flush"
      print ""
    }' "${WORKDATA_PASS}"
  } > "${PROXY_CFG_PASS}"
}

gen_cfg_ip_port() {
  {
    cat <<EOF
daemon
maxconn 12000
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
    }' "${WORKDATA_IP_PORT}"
  } > "${PROXY_CFG_IP_PORT}"
}

gen_proxy_lists() {
  awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2}' "${WORKDATA_PASS}" > "${WORKDIR}/proxy_full4k_pass.txt"
  awk -F "/" '{print $1 ":" $2}' "${WORKDATA_IP_PORT}" > "${WORKDIR}/proxy_full4k_ip_port.txt"
}

create_services() {
  cat > "${SERVICE_PASS}" <<EOF
[Unit]
Description=3proxy full4k HTTP auth
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/bin/bash ${BOOT_SCRIPT}
ExecStart=${PROXY_BIN} ${PROXY_CFG_PASS}
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  cat > "${SERVICE_IP_PORT}" <<EOF
[Unit]
Description=3proxy full4k HTTP no-auth
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/bin/bash ${BOOT_SCRIPT}
ExecStart=${PROXY_BIN} ${PROXY_CFG_IP_PORT}
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
}

cleanup_old_state() {
  local iface="$1"
  echo "[*] Cleaning old full4k state..."

  systemctl stop 3proxy-full4k-pass >/dev/null 2>&1 || true
  systemctl stop 3proxy-full4k-ip-port >/dev/null 2>&1 || true

  if [[ -f "${WORKDATA_PASS}" ]]; then
    while IFS='/' read -r _user _pass _ip4 _port ipv6; do
      ip -6 addr del "${ipv6}/64" dev "${iface}" 2>/dev/null || true
    done < "${WORKDATA_PASS}"
  fi
  if [[ -f "${WORKDATA_IP_PORT}" ]]; then
    while IFS='/' read -r _ip4 _port ipv6; do
      ip -6 addr del "${ipv6}/64" dev "${iface}" 2>/dev/null || true
    done < "${WORKDATA_IP_PORT}"
  fi

  rm -f "${WORKDATA_PASS}" \
        "${WORKDATA_IP_PORT}" \
        "${WORKDIR}/proxy_full4k_pass.txt" \
        "${WORKDIR}/proxy_full4k_ip_port.txt" \
        "${BOOT_SCRIPT}" \
        "${PROXY_CFG_PASS}" \
        "${PROXY_CFG_IP_PORT}"
}

main() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Hãy chạy script bằng root."
    exit 1
  fi

  mkdir -p "${WORKDIR}"

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
  echo "[*] HTTP pass ports: ${FIRST_PORT_PASS}-${LAST_PORT_PASS} (${COUNT} proxies)"
  echo "[*] HTTP ip:port ports: ${FIRST_PORT_IP_PORT}-${LAST_PORT_IP_PORT} (${COUNT} proxies)"

  cleanup_old_state "${iface}"
  gen_data_pass "${ip4}" "${ip6_prefix}"
  gen_data_ip_port "${ip4}" "${ip6_prefix}"
  gen_if_script "${iface}"
  gen_cfg_pass
  gen_cfg_ip_port
  gen_proxy_lists
  create_services

  echo "[*] Starting full4k services..."
  systemctl daemon-reload
  systemctl enable --now 3proxy-full4k-pass
  systemctl enable --now 3proxy-full4k-ip-port

  echo "[*] Done."
  echo "[*] HTTP pass list: ${WORKDIR}/proxy_full4k_pass.txt"
  echo "[*] HTTP no-auth list: ${WORKDIR}/proxy_full4k_ip_port.txt"
  echo "[*] HTTP pass count: $(wc -l < "${WORKDIR}/proxy_full4k_pass.txt")"
  echo "[*] HTTP no-auth count: $(wc -l < "${WORKDIR}/proxy_full4k_ip_port.txt")"
}

main "$@"
