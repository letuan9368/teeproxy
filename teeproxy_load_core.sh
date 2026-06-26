#!/usr/bin/env bash
# Shared loader: require Tee-Proxy-Core-v2.sh in the same directory.
teeproxy_load_core() {
  local caller="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  local script_dir
  script_dir="$(cd "$(dirname "${caller}")" && pwd)"
  local core="${script_dir}/Tee-Proxy-Core-v2.sh"

  if [[ ! -f "${core}" ]]; then
    echo "Không tìm thấy Tee-Proxy-Core-v2.sh trong ${script_dir}"
    echo "Upload cả thư mục Bash proxy lên VPS (scp/rsync), rồi chạy lại."
    exit 1
  fi

  # shellcheck source=/dev/null
  source "${core}"
}
