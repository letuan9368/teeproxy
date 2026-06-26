# Upload bộ script TeeProxy từ Windows lên VPS
# Cách dùng:
#   .\upload-to-vps.ps1 -VpsIp "1.2.3.4" -User root
#   .\upload-to-vps.ps1 -VpsIp "1.2.3.4" -User root -Port 22 -RemoteDir /root/teeproxy

param(
    [Parameter(Mandatory = $true)]
    [string]$VpsIp,

    [string]$User = "root",
    [int]$Port = 22,
    [string]$RemoteDir = "/root/teeproxy"
)

$LocalDir = $PSScriptRoot
$ScpTarget = "${User}@${VpsIp}:${RemoteDir}/"

Write-Host "[*] Tao thu muc tren VPS: ${RemoteDir}"
ssh -p $Port "${User}@${VpsIp}" "mkdir -p '${RemoteDir}'"

Write-Host "[*] Upload *.sh tu: $LocalDir"
scp -P $Port "$LocalDir\*.sh" $ScpTarget

Write-Host "[*] Chuyen LF (tranh loi CRLF Windows tren Linux)"
ssh -p $Port "${User}@${VpsIp}" "sed -i 's/\r$//' '${RemoteDir}'/*.sh"

Write-Host "[*] Phan quyen thuc thi"
ssh -p $Port "${User}@${VpsIp}" "chmod +x '${RemoteDir}'/*.sh"

Write-Host ""
Write-Host "Xong. SSH vao VPS va chay:"
Write-Host "  cd ${RemoteDir}"
Write-Host "  bash Tee-Proxy-IP-Port.sh"
Write-Host ""
Write-Host "Hoac cai dat:"
Write-Host "  bash Tee-Proxy-Install.sh ${RemoteDir}"
