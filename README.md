# DXVPN AIO
- `Note !!! for multipath please change to Xray-core mod in menu script`

# UPDATES LOG

- `ADD DNS SETTING`

# Required
- DOMAIN (MUST)
- DEBIAN 9/10
- Ubuntu 18/20 LTS
- CPU MIN 1 CORE
- RAM 1GB

|  SERVICE  |  NETWORK PORT  |
|---------- |--------|
| Vmess WS TLS (multipath)  | 443 |
| Vless WS TLS  | 443 |
| Trojan WS TLS  | 443 |
| Socks5 WS TLS  | 443 |
| Shadowsocks WS TLS (aes-256-gcm)  | 443 |
| Shadowsocks 2022 WS TLS (2022-blake3-aes-256-gcm)  | 443 |
| Vmess WS (multipath)  | 80 |
| Vless WS  | 80 |
| Trojan WS  | 80 |
| Socks5 WS  | 80 |
| Shadowsocks WS (aes-256-gcm)  | 80 |
| Shadowsocks 2022 WS (2022-blake3-aes-256-gcm)  | 80 |
| Vmess gRPC  | 443 |
| Vless gRPC  | 443 |
| Trojan gRPC  | 443 |
| Socks5 gRPC  | 443 |
| Shadowsocks gRPC (aes-256-gcm)  | 443 |
| Shadowsocks 2022 gRPC (2022-blake3-aes-256-gcm)  | 443 |
| Nginx Webserver | 8000 |
| Auto Delete Expired Account | ✅ |
| DNS Setting | ✅ |

|  ALTERNATIF PORT  |  NETWORK PORT  |
|-------------------|--------|
| HTTPS  | 2053, 2083, 2087, 2096, 8443 |
| HTTP  | 8080, 8880, 2052, 2082, 2086, 2095 |

# Setup DNS Cloudflare

|  RECORD TYPE | TTL   |
|-------------------|--------|
| A = DNS ONLY  | AUTO TTL |
| CNAME = DNS ONLY | AUTO TTL |


# Example

|  RECORD TYPE | TTL | DOMAIN|
|-------------------|--------|--------|
| A  | AUTO TTL |test.yourdomain.tld |
| CNAME  | AUTO TTL | *.test.yourdomain.tld |


# Installation
- via WGET
```
bash -c "$(wget -qO- https://raw.githubusercontent.com/thoiruddin/DXVPN/master/xray)"
```
- via CURL
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/thoiruddin/DXVPN/master/xray)"
```
