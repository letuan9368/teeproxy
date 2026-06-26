#!/usr/bin/env bash
set -euo pipefail

# Sửa repo AlmaLinux khi dnf treo / baseurl hỏng.
# Chạy trên VPS AlmaLinux 8.9 trước khi deploy proxy.

if [[ "${EUID}" -ne 0 ]]; then
  echo "Hãy chạy bằng root."
  exit 1
fi

pkill -f dnf || true
rm -f /var/run/dnf.pid

cat > /etc/yum.repos.d/almalinux.repo <<'EOF'
[baseos]
name=AlmaLinux 8.9 - BaseOS
baseurl=https://repo.almalinux.org/vault/8.9/BaseOS/x86_64/os/
enabled=1
gpgcheck=0

[appstream]
name=AlmaLinux 8.9 - AppStream
baseurl=https://repo.almalinux.org/vault/8.9/AppStream/x86_64/os/
enabled=1
gpgcheck=0

[extras]
name=AlmaLinux 8.9 - Extras
baseurl=https://repo.almalinux.org/vault/8.9/extras/x86_64/os/
enabled=1
gpgcheck=0

[powertools]
name=AlmaLinux 8.9 - PowerTools
baseurl=https://repo.almalinux.org/vault/8.9/PowerTools/x86_64/os/
enabled=1
gpgcheck=0
EOF

rm -f /etc/yum.repos.d/almalinux-*.repo
dnf clean all
dnf makecache

echo "[*] Repo AlmaLinux đã sửa. Thử: dnf install -y gcc make wget tar curl iproute"
