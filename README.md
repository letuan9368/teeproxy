# Tee-Proxy-Pass

Script cài `3proxy` cho AlmaLinux, hỗ trợ tối đa `2000` IPv6 proxies.

## Chạy nhanh trên VPS

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Pass.sh && chmod +x Tee-Proxy-Pass.sh && bash Tee-Proxy-Pass.sh
```

## Tuỳ chọn tham số

```bash
bash Tee-Proxy-Pass.sh [COUNT] [FIRST_PORT]
```

- `COUNT`: số proxy cần tạo (1 -> 2000), mặc định `2000`
- `FIRST_PORT`: port bắt đầu, mặc định `22000`

Ví dụ:

```bash
bash Tee-Proxy-Pass.sh 1500 30000
```

## Output

- Danh sách proxy: `/home/bkns/proxy.txt`
- Service: `3proxy-custom`
- Username tạo theo mẫu: `teeblack` + `5 số ngẫu nhiên` (ví dụ `teeblack48291`)
- Mỗi lần chạy script sẽ dọn cấu hình/proxy cũ và tạo mới hoàn toàn

---

# Tee-Proxy-IP-Port

Script tạo proxy không user/pass (chỉ `IP:PORT`), tối đa `2000` proxies.

## Chạy nhanh trên VPS

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-IP-Port.sh && chmod +x Tee-Proxy-IP-Port.sh && bash Tee-Proxy-IP-Port.sh
```

## Tuỳ chọn tham số

```bash
bash Tee-Proxy-IP-Port.sh [COUNT] [FIRST_PORT]
```

- `COUNT`: số proxy cần tạo (1 -> 2000), mặc định `2000`
- `FIRST_PORT`: port bắt đầu, mặc định `22000`

## Output

- Danh sách proxy: `/home/bkns/proxy_ip_port.txt`
- Service: `3proxy-ip-port`

---

# Tee-Proxy-Socks5-Pass

Script tạo SOCKS5 proxy có user/pass, tối đa `2000` proxies.

## Chạy nhanh trên VPS

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Socks5-Pass.sh && chmod +x Tee-Proxy-Socks5-Pass.sh && bash Tee-Proxy-Socks5-Pass.sh
```

## Tuỳ chọn tham số

```bash
bash Tee-Proxy-Socks5-Pass.sh [COUNT] [FIRST_PORT]
```

- `COUNT`: số proxy cần tạo (1 -> 2000), mặc định `2000`
- `FIRST_PORT`: port bắt đầu, mặc định `22000`
- Username: `teeblack` + 5 số ngẫu nhiên
- Password: random 8 ký tự (A-Z, a-z, 0-9)

## Output

- Danh sách proxy: `/home/bkns/proxy_socks5_pass.txt` (`IP:PORT:USER:PASS`)
- Service: `3proxy-socks5-pass`

---

# Tee-Proxy-Socks5-IP-Port

Script tạo SOCKS5 proxy không auth (chỉ `IP:PORT`), tối đa `2000` proxies.

## Chạy nhanh trên VPS

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Socks5-IP-Port.sh && chmod +x Tee-Proxy-Socks5-IP-Port.sh && bash Tee-Proxy-Socks5-IP-Port.sh
```

## Tuỳ chọn tham số

```bash
bash Tee-Proxy-Socks5-IP-Port.sh [COUNT] [FIRST_PORT]
```

- `COUNT`: số proxy cần tạo (1 -> 2000), mặc định `2000`
- `FIRST_PORT`: port bắt đầu, mặc định `22000`

## Output

- Danh sách proxy: `/home/bkns/proxy_socks5_ip_port.txt` (`IP:PORT`)
- Service: `3proxy-socks5-ip-port`

---

# Tee-Proxy-Full-4k

Script tạo cùng lúc 2 loại HTTP:
- HTTP có pass (`IP:PORT:USER:PASS`)
- HTTP không pass (`IP:PORT`)

Mỗi loại mặc định `4000` proxy.

## Chạy nhanh trên VPS

```bash
wget https://raw.githubusercontent.com/letuan9368/teeproxy/master/Tee-Proxy-Full-4k.sh && chmod +x Tee-Proxy-Full-4k.sh && bash Tee-Proxy-Full-4k.sh
```

## Tuỳ chọn tham số

```bash
bash Tee-Proxy-Full-4k.sh [COUNT] [FIRST_PORT_PASS] [FIRST_PORT_IP_PORT]
```

- `COUNT`: số proxy mỗi loại (1 -> 4000), mặc định `4000`
- `FIRST_PORT_PASS`: port bắt đầu cho loại có pass, mặc định `22000`
- `FIRST_PORT_IP_PORT`: port bắt đầu cho loại không pass, mặc định `27000`

## Output

- HTTP có pass: `/home/bkns/proxy_full4k_pass.txt`
- HTTP không pass: `/home/bkns/proxy_full4k_ip_port.txt`
- Services:
  - `3proxy-full4k-pass`
  - `3proxy-full4k-ip-port`
