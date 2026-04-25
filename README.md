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
