# TeeProxy v2 Premium

Bộ script premium cho AlmaLinux 8/9, ưu tiên ổn định tải cao:
- chạy `3proxy` qua `systemd` foreground (không `daemon` loop)
- áp dụng tuning kernel + `nofile` cao
- dùng route local IPv6 `/64` (nhẹ hơn add từng IP)
- auto dọn và deploy lại sạch mỗi lần chạy

## 1) HTTP có pass

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Pass.sh && chmod +x Tee-Proxy-Pass.sh && bash Tee-Proxy-Pass.sh
```

- Tham số: `bash Tee-Proxy-Pass.sh [COUNT] [FIRST_PORT]`
- Mặc định: `2000`, `22000`
- Output: `/home/bkns/proxy.txt` (`IP:PORT:USER:PASS`)
- Service: `3proxy-custom`

## 2) HTTP không pass

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-IP-Port.sh && chmod +x Tee-Proxy-IP-Port.sh && bash Tee-Proxy-IP-Port.sh
```

- Tham số: `bash Tee-Proxy-IP-Port.sh [COUNT] [FIRST_PORT]`
- Output: `/home/bkns/proxy_ip_port.txt` (`IP:PORT`)
- Service: `3proxy-ip-port`

## 3) SOCKS5 có pass

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Socks5-Pass.sh && chmod +x Tee-Proxy-Socks5-Pass.sh && bash Tee-Proxy-Socks5-Pass.sh
```

- Tham số: `bash Tee-Proxy-Socks5-Pass.sh [COUNT] [FIRST_PORT]`
- Output: `/home/bkns/proxy_socks5_pass.txt` (`IP:PORT:USER:PASS`)
- Service: `3proxy-socks5-pass`

## 4) SOCKS5 không pass

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Socks5-IP-Port.sh && chmod +x Tee-Proxy-Socks5-IP-Port.sh && bash Tee-Proxy-Socks5-IP-Port.sh
```

- Tham số: `bash Tee-Proxy-Socks5-IP-Port.sh [COUNT] [FIRST_PORT]`
- Output: `/home/bkns/proxy_socks5_ip_port.txt` (`IP:PORT`)
- Service: `3proxy-socks5-ip-port`

## 5) Full HTTP 4k + 4k

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Full-4k.sh && chmod +x Tee-Proxy-Full-4k.sh && bash Tee-Proxy-Full-4k.sh
```

- Tham số: `bash Tee-Proxy-Full-4k.sh [COUNT] [FIRST_PORT_PASS] [FIRST_PORT_IP_PORT]`
- Mặc định: `4000`, `22000`, `27000`
- Output:
  - `/home/bkns/proxy_full4k_pass.txt`
  - `/home/bkns/proxy_full4k_ip_port.txt`
- Services dùng chung:
  - `3proxy-custom`
  - `3proxy-ip-port`

## 6) Full SOCKS5 4k + 4k

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-S5-Full-4k.sh && chmod +x Tee-Proxy-S5-Full-4k.sh && bash Tee-Proxy-S5-Full-4k.sh
```

- Tham số: `bash Tee-Proxy-S5-Full-4k.sh [COUNT] [FIRST_PORT_PASS] [FIRST_PORT_IP_PORT]`
- Mặc định: `4000`, `32000`, `37000`
- Output:
  - `/home/bkns/proxy_s5_full4k_pass.txt`
  - `/home/bkns/proxy_s5_full4k_ip_port.txt`
- Services dùng chung:
  - `3proxy-socks5-pass`
  - `3proxy-socks5-ip-port`

## 7) Tuning riêng

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Optimize.sh && chmod +x Tee-Proxy-Optimize.sh && bash Tee-Proxy-Optimize.sh
```

## 8) Healthcheck nhanh

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Check.sh && chmod +x Tee-Proxy-Check.sh && bash Tee-Proxy-Check.sh /home/bkns/proxy.txt 20
```

## Gợi ý vận hành ổn định

- VPS 8 vCPU/16 GB RAM trở lên nếu chạy profile 4k + 4k.
- Nếu mới deploy: chạy 1000 trước, tăng dần 2000 rồi 4000.
- Mặc định script chạy `TEEPROXY_IP_MODE=auto`:
  - có IPv6 outbound -> dùng IPv6 proxy
  - không có IPv6 outbound -> tự fallback IPv4-only
- Ép mode khi cần:
  - `TEEPROXY_IP_MODE=ipv4 bash Tee-Proxy-Pass.sh`
  - `TEEPROXY_IP_MODE=ipv6 bash Tee-Proxy-Pass.sh`
- Kiểm tra nhanh:
  - `systemctl is-active 3proxy-custom`
  - `ss -lntp | rg 3proxy | head`
