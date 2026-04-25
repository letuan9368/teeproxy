#!/usr/bin/env bash
set -euo pipefail

# Premium core for all Tee-Proxy scripts.
# Modes:
#   http_pass, http_ipport, socks5_pass, socks5_ipport,
#   http_full4k, socks5_full4k

WORKDIR="/home/bkns"
PREFIX_FILE="${WORKDIR}/.teeproxy_ipv6_prefix"
PROXY_BIN="/usr/local/etc/3proxy/bin/3proxy"
SYSTEM_LIMITS="/etc/security/limits.d/99-teeproxy.conf"
SYSCTL_FILE="/etc/sysctl.d/99-teeproxy.conf"

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

detect_iface() {
  ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

detect_ipv6_prefix() {
  local raw
  raw="$(curl -6 -s --max-time 8 icanhazip.com || true)"
  if [[ -z "${raw}" ]]; then
    echo ""
    return
  fi
  echo "${raw}" | awk -F: '{print $1 ":" $2 ":" $3 ":" $4}'
}

ensure_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Hãy chạy script bằng root."
    exit 1
  fi
}

ensure_count_and_ports() {
  local count="$1"
  local p1="$2"
  local max="$3"
  local p2="${4:-}"
  if ! [[ "$count" =~ ^[0-9]+$ ]] || ! [[ "$p1" =~ ^[0-9]+$ ]]; then
    echo "COUNT và PORT phải là số nguyên dương."
    exit 1
  fi
  if [[ -n "${p2}" ]] && ! [[ "$p2" =~ ^[0-9]+$ ]]; then
    echo "PORT phải là số nguyên dương."
    exit 1
  fi
  if (( count < 1 || count > max )); then
    echo "COUNT phải từ 1 đến ${max}."
    exit 1
  fi
}

install_deps() {
  dnf -y install gcc make wget tar curl iproute --nobest --skip-broken >/dev/null
}

install_3proxy_if_needed() {
  if [[ -x "${PROXY_BIN}" ]]; then
    return
  fi
  local build_dir="/root/3proxy-0.8.13"
  local url="https://github.com/z3APA3A/3proxy/archive/refs/tags/0.8.13.tar.gz"
  echo "[*] Installing 3proxy 0.8.13..."
  rm -rf /root/3proxy-0.8.13 /root/3proxy-0.8.13.tar.gz
  wget -qO /root/3proxy-0.8.13.tar.gz "${url}"
  tar -xzf /root/3proxy-0.8.13.tar.gz -C /root
  cd "${build_dir}"
  make -f Makefile.Linux
  mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
  install -m 755 src/3proxy "${PROXY_BIN}"
  cd /root
}

apply_system_tuning() {
  cat > "${SYSCTL_FILE}" <<EOF
fs.file-max = 2000000
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 262144
net.netfilter.nf_conntrack_max = 1048576
EOF
  sysctl --system >/dev/null 2>&1 || true

  cat > "${SYSTEM_LIMITS}" <<EOF
* soft nofile 200000
* hard nofile 200000
root soft nofile 200000
root hard nofile 200000
EOF
}

ensure_ipv6_local_route() {
  local prefix="$1"
  local cidr="${prefix}::/64"
  if ip -6 route show table local | grep -q "${prefix}::/64"; then
    :
  else
    ip -6 route add local "${cidr}" dev lo table local 2>/dev/null || true
  fi
  echo "${prefix}" > "${PREFIX_FILE}"
}

stop_and_clean_service() {
  local service="$1"
  local data_file="$2"
  local cfg_file="$3"
  local list_file="$4"
  systemctl stop "${service}" >/dev/null 2>&1 || true
  rm -f "${data_file}" "${cfg_file}" "${list_file}"
}

write_service_file() {
  local service="$1"
  local cfg="$2"
  cat > "/etc/systemd/system/${service}.service" <<EOF
[Unit]
Description=${service}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${PROXY_BIN} ${cfg}
Restart=always
RestartSec=2
TimeoutStartSec=0
LimitNOFILE=200000

[Install]
WantedBy=multi-user.target
EOF
}

common_header_cfg() {
  cat <<EOF
maxconn 20000
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
EOF
}

deploy_single_mode() {
  local mode="$1"
  local count="$2"
  local first_port="$3"
  local ip4="$4"
  local ip6_prefix="$5"
  local last_port=$((first_port + count - 1))

  if (( last_port > 65535 )); then
    echo "Dải port không hợp lệ: ${first_port}-${last_port}."
    exit 1
  fi

  local data_file cfg_file out_file service auth_type cmd_type
  case "${mode}" in
    http_pass)
      data_file="${WORKDIR}/data.txt"
      cfg_file="/usr/local/etc/3proxy/3proxy.cfg"
      out_file="${WORKDIR}/proxy.txt"
      service="3proxy-custom"
      auth_type="strong"
      cmd_type="proxy"
      ;;
    http_ipport)
      data_file="${WORKDIR}/data_ip_port.txt"
      cfg_file="/usr/local/etc/3proxy/3proxy-ip-port.cfg"
      out_file="${WORKDIR}/proxy_ip_port.txt"
      service="3proxy-ip-port"
      auth_type="none"
      cmd_type="proxy"
      ;;
    socks5_pass)
      data_file="${WORKDIR}/data_socks5.txt"
      cfg_file="/usr/local/etc/3proxy/3proxy-socks5-pass.cfg"
      out_file="${WORKDIR}/proxy_socks5_pass.txt"
      service="3proxy-socks5-pass"
      auth_type="strong"
      cmd_type="socks"
      ;;
    socks5_ipport)
      data_file="${WORKDIR}/data_socks5_ip_port.txt"
      cfg_file="/usr/local/etc/3proxy/3proxy-socks5-ipport.cfg"
      out_file="${WORKDIR}/proxy_socks5_ip_port.txt"
      service="3proxy-socks5-ip-port"
      auth_type="none"
      cmd_type="socks"
      ;;
    *)
      echo "Mode không hỗ trợ: ${mode}"
      exit 1
      ;;
  esac

  stop_and_clean_service "${service}" "${data_file}" "${cfg_file}" "${out_file}"
  mkdir -p "${WORKDIR}"

  : > "${data_file}"
  if [[ "${auth_type}" == "strong" ]]; then
    declare -A used_users=()
    for ((port=first_port; port<=last_port; port++)); do
      local user suffix
      while true; do
        suffix="$(random_5_digits)"
        user="teeblack${suffix}"
        [[ -z "${used_users[$user]+x}" ]] && break
      done
      used_users["${user}"]=1
      echo "${user}/$(random_pass)/${ip4}/${port}/$(gen_ipv6 "${ip6_prefix}")" >> "${data_file}"
    done
  else
    for ((port=first_port; port<=last_port; port++)); do
      echo "${ip4}/${port}/$(gen_ipv6 "${ip6_prefix}")" >> "${data_file}"
    done
  fi

  {
    common_header_cfg
    if [[ "${auth_type}" == "strong" ]]; then
      echo "auth strong"
      echo
      echo "users $(awk -F "/" 'BEGIN{ORS=""} {print $1 ":CL:" $2 " "}' "${data_file}")"
      echo
      awk -F "/" -v cmd="${cmd_type}" '{
        print "auth strong"
        print "allow " $1
        print cmd " -6 -n -a -p" $4 " -i" $3 " -e" $5
        print "flush"
        print ""
      }' "${data_file}"
    else
      echo "auth none"
      echo "allow *"
      echo
      awk -F "/" -v cmd="${cmd_type}" '{
        print cmd " -6 -n -a -p" $2 " -i" $1 " -e" $3
        print "flush"
        print ""
      }' "${data_file}"
    fi
  } > "${cfg_file}"

  if [[ "${auth_type}" == "strong" ]]; then
    awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2}' "${data_file}" > "${out_file}"
  else
    awk -F "/" '{print $1 ":" $2}' "${data_file}" > "${out_file}"
  fi

  write_service_file "${service}" "${cfg_file}"
  systemctl daemon-reload
  systemctl enable --now "${service}" >/dev/null

  echo "[*] Mode: ${mode}"
  echo "[*] Service: ${service} -> $(systemctl is-active "${service}")"
  echo "[*] Output: ${out_file}"
  echo "[*] Count: $(wc -l < "${out_file}")"
}

deploy_dual_mode() {
  local mode="$1"
  local count="$2"
  local p1="$3"
  local p2="$4"
  local ip4="$5"
  local ip6_prefix="$6"
  local last1=$((p1 + count - 1))
  local last2=$((p2 + count - 1))

  if (( last1 > 65535 || last2 > 65535 )); then
    echo "Dải port không hợp lệ."
    exit 1
  fi
  if (( p1 <= last2 && p2 <= last1 )); then
    echo "2 dải port đang trùng nhau."
    exit 1
  fi

  if [[ "${mode}" == "http_full4k" ]]; then
    deploy_single_mode "http_pass" "${count}" "${p1}" "${ip4}" "${ip6_prefix}"
    deploy_single_mode "http_ipport" "${count}" "${p2}" "${ip4}" "${ip6_prefix}"
    cp -f "${WORKDIR}/proxy.txt" "${WORKDIR}/proxy_full4k_pass.txt"
    cp -f "${WORKDIR}/proxy_ip_port.txt" "${WORKDIR}/proxy_full4k_ip_port.txt"
    echo "[*] Full output (HTTP pass): ${WORKDIR}/proxy_full4k_pass.txt"
    echo "[*] Full output (HTTP no-auth): ${WORKDIR}/proxy_full4k_ip_port.txt"
  elif [[ "${mode}" == "socks5_full4k" ]]; then
    deploy_single_mode "socks5_pass" "${count}" "${p1}" "${ip4}" "${ip6_prefix}"
    deploy_single_mode "socks5_ipport" "${count}" "${p2}" "${ip4}" "${ip6_prefix}"
    cp -f "${WORKDIR}/proxy_socks5_pass.txt" "${WORKDIR}/proxy_s5_full4k_pass.txt"
    cp -f "${WORKDIR}/proxy_socks5_ip_port.txt" "${WORKDIR}/proxy_s5_full4k_ip_port.txt"
    echo "[*] Full output (SOCKS5 pass): ${WORKDIR}/proxy_s5_full4k_pass.txt"
    echo "[*] Full output (SOCKS5 no-auth): ${WORKDIR}/proxy_s5_full4k_ip_port.txt"
  else
    echo "Mode dual không hỗ trợ: ${mode}"
    exit 1
  fi
}

run_mode() {
  local mode="$1"
  local count="$2"
  local p1="$3"
  local p2="${4:-}"

  ensure_root
  install_deps
  install_3proxy_if_needed
  apply_system_tuning

  local ip4 ip6_prefix iface
  ip4="$(curl -4 -s --max-time 8 icanhazip.com || true)"
  ip6_prefix="$(detect_ipv6_prefix)"
  iface="$(detect_iface)"

  if [[ -z "${ip4}" || -z "${ip6_prefix}" || -z "${iface}" ]]; then
    echo "Không lấy được IP/interface. Kiểm tra network + IPv6."
    exit 1
  fi

  ensure_ipv6_local_route "${ip6_prefix}"

  echo "[*] IPv4: ${ip4}"
  echo "[*] IPv6 prefix: ${ip6_prefix}"
  echo "[*] Interface: ${iface}"

  case "${mode}" in
    http_pass|http_ipport|socks5_pass|socks5_ipport)
      deploy_single_mode "${mode}" "${count}" "${p1}" "${ip4}" "${ip6_prefix}"
      ;;
    http_full4k|socks5_full4k)
      deploy_dual_mode "${mode}" "${count}" "${p1}" "${p2}" "${ip4}" "${ip6_prefix}"
      ;;
    *)
      echo "Mode không hỗ trợ: ${mode}"
      exit 1
      ;;
  esac
}
