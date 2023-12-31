rm -rf install
clear
BGreen='\e[1;32m'
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
secs_to_human() {
echo -e "${WB}Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds${NC}"
}
start=$(date +%s)
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt install socat netfilter-persistent -y
apt install vnstat lsof fail2ban -y
apt install curl sudo -y
apt install screen cron screenfetch -y
mkdir /backup >> /dev/null 2>&1
mkdir /user >> /dev/null 2>&1
mkdir /tmp >> /dev/null 2>&1
apt install resolvconf network-manager dnsutils bind9 -y
cat > /etc/systemd/resolved.conf << END
[Resolve]
DNS=8.8.8.8 8.8.4.4
Domains=~.
ReadEtcHosts=yes
END
systemctl enable resolvconf
systemctl enable systemd-resolved
systemctl enable NetworkManager
rm -rf /etc/resolv.conf
rm -rf /etc/resolvconf/resolv.conf.d/head
echo "
nameserver 127.0.0.53
" >> /etc/resolv.conf
echo "
" >> /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf
systemctl restart systemd-resolved
systemctl restart NetworkManager
echo "Google DNS" > /user/current
rm /usr/local/etc/xray/city >> /dev/null 2>&1
rm /usr/local/etc/xray/org >> /dev/null 2>&1
rm /usr/local/etc/xray/timezone >> /dev/null 2>&1
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install --beta
cp /usr/local/bin/xray /backup/xray.official.backup
curl -s ipinfo.io/city >> /usr/local/etc/xray/city
curl -s ipinfo.io/org | cut -d " " -f 2-10 >> /usr/local/etc/xray/org
curl -s ipinfo.io/timezone >> /usr/local/etc/xray/timezone
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Xray-core mod${NC}"
sleep 0.5
wget -q -O /backup/xray.mod.backup "https://github.com/dharak36/Xray-core/releases/download/v1.0.0/xray.linux.64bit"
echo -e "${GB}[ INFO ]${NC} ${YB}Download Xray-core done${NC}"
sleep 1
cd
clear
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
clear
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
apt install nginx -y
rm /var/www/html/*.html
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
mkdir -p /var/www/html/vmess
mkdir -p /var/www/html/vless
mkdir -p /var/www/html/trojan
mkdir -p /var/www/html/shadowsocks
mkdir -p /var/www/html/shadowsocks2022
mkdir -p /var/www/html/socks5
mkdir -p /var/www/html/allxray
systemctl restart nginx
clear
touch /usr/local/etc/xray/domain
echo -e "${YB}Input Domain${NC} "
echo " "
read -rp "Input your domain : " -e dns
if [ -z $dns ]; then
echo -e "Nothing input for domain!"
else
echo "$dns" > /usr/local/etc/xray/domain
echo "DNS=$dns" > /var/lib/dnsvps.conf
fi
clear
systemctl stop nginx
systemctl stop xray
domain=$(cat /usr/local/etc/xray/domain)
curl https://get.acme.sh | sh
source ~/.bashrc
cd .acme.sh
bash acme.sh --issue -d $domain --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.crt --key-file /usr/local/etc/xray/private.key --standalone --force
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Nginx & Xray Configuration${NC}"
echo "UQ3w2q98BItd3DPgyctdoJw4cqQFmY59ppiDQdqMKbw=" > /usr/local/etc/xray/serverpsk
wget -q -O /usr/local/etc/xray/config.json https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/config.json
wget -q -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/nginx.conf
wget -q -O /etc/nginx/conf.d/xray.conf https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/xray.conf
systemctl restart nginx
systemctl restart xray
mkdir /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
rm /etc/nginx/conf.d/default.conf
systemctl daemon-reload
service nginx restart
cd
mkdir /home/vps
mkdir /home/vps/public_html
wget -O /home/vps/public_html/index.html "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/index"
wget -O /home/vps/public_html/.htaccess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/.htaccess"
mkdir /home/vps/public_html/ss-ws
mkdir /home/vps/public_html/clash-ws
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Done${NC}"
sleep 2
clear
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
cd /usr/bin
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Main Menu${NC}"
wget -q -O menu "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/menu.sh"
wget -q -O vmess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/vmess.sh"
wget -q -O vless "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/vless.sh"
wget -q -O trojan "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/trojan.sh"
wget -q -O shadowsocks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/shadowsocks.sh"
wget -q -O shadowsocks2022 "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/shadowsocks2022.sh"
wget -q -O socks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/socks.sh"
wget -q -O allxray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/allxray.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Vmess${NC}"
wget -q -O add-vmess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vmess/add-vmess.sh"
wget -q -O del-vmess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vmess/del-vmess.sh"
wget -q -O extend-vmess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vmess/extend-vmess.sh"
wget -q -O trialvmess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vmess/trialvmess.sh"
wget -q -O check-vmess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vmess/check-vmess.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Vless${NC}"
wget -q -O add-vless "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vless/add-vless.sh"
wget -q -O del-vless "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vless/del-vless.sh"
wget -q -O extend-vless "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vless/extend-vless.sh"
wget -q -O trialvless "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vless/trialvless.sh"
wget -q -O check-vless "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/vless/check-vless.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Trojan${NC}"
wget -q -O add-trojan "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/trojan/add-trojan.sh"
wget -q -O del-trojan "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/trojan/del-trojan.sh"
wget -q -O extend-trojan "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/trojan/extend-trojan.sh"
wget -q -O trialtrojan "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/trojan/trialtrojan.sh"
wget -q -O check-trojan "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/trojan/check-trojan.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Shadowsocks${NC}"
wget -q -O add-ss "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks/add-ss.sh"
wget -q -O del-ss "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks/del-ss.sh"
wget -q -O extend-ss "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks/extend-ss.sh"
wget -q -O trialss "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks/trialss.sh"
wget -q -O check-ss "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks/check-ss.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Shadowsocks 2022${NC}"
wget -q -O add-ss2022 "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks2022/add-ss2022.sh"
wget -q -O del-ss2022 "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks2022/del-ss2022.sh"
wget -q -O extend-ss2022 "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks2022/extend-ss2022.sh"
wget -q -O trialss2022 "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks2022/trialss2022.sh"
wget -q -O check-ss2022 "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/shadowsocks2022/check-ss2022.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Socks5${NC}"
wget -q -O add-socks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/socks/add-socks.sh"
wget -q -O del-socks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/socks/del-socks.sh"
wget -q -O extend-socks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/socks/extend-socks.sh"
wget -q -O trialsocks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/socks/trialsocks.sh"
wget -q -O check-socks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/socks/check-socks.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu All Xray${NC}"
wget -q -O add-xray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/allxray/add-xray.sh"
wget -q -O del-xray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/allxray/del-xray.sh"
wget -q -O extend-xray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/allxray/extend-xray.sh"
wget -q -O trialxray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/allxray/trialxray.sh"
wget -q -O check-xray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/allxray/check-xray.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Log${NC}"
wget -q -O log-create "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-create.sh"
wget -q -O log-vmess "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-vmess.sh"
wget -q -O log-vless "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-vless.sh"
wget -q -O log-trojan "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-trojan.sh"
wget -q -O log-ss "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-ss.sh"
wget -q -O log-ss2022 "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-ss2022.sh"
wget -q -O log-socks "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-socks.sh"
wget -q -O log-allxray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/log/log-allxray.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Other Menu${NC}"
wget -q -O xp "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/xp.sh"
wget -q -O dns "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/dns.sh"
wget -q -O certxray "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/certxray.sh"
wget -q -O xraymod "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/xraymod.sh"
wget -q -O xrayofficial "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/xrayofficial.sh"
wget -q -O about "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/about.sh"
wget -q -O clear-log "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/clear-log.sh"
wget -q -O changer "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/other/changer.sh"
wget -q -O telebot "https://raw.githubusercontent.com/thoiruddin/DXVPN/master/menu/bot.sh"
echo -e "${GB}[ INFO ]${NC} ${YB}Download All Menu Done${NC}"
sleep 2
chmod +x add-vmess
chmod +x del-vmess
chmod +x extend-vmess
chmod +x trialvmess
chmod +x check-vmess
chmod +x add-vless
chmod +x del-vless
chmod +x extend-vless
chmod +x trialvless
chmod +x check-vless
chmod +x add-trojan
chmod +x del-trojan
chmod +x extend-trojan
chmod +x trialtrojan
chmod +x check-trojan
chmod +x add-ss
chmod +x del-ss
chmod +x extend-ss
chmod +x trialss
chmod +x check-ss
chmod +x add-ss2022
chmod +x del-ss2022
chmod +x extend-ss2022
chmod +x trialss2022
chmod +x check-ss2022
chmod +x add-socks
chmod +x del-socks
chmod +x extend-socks
chmod +x trialsocks
chmod +x check-socks
chmod +x add-xray
chmod +x del-xray
chmod +x extend-xray
chmod +x trialxray
chmod +x check-xray
chmod +x log-create
chmod +x log-vmess
chmod +x log-vless
chmod +x log-trojan
chmod +x log-ss
chmod +x log-ss2022
chmod +x log-socks
chmod +x log-allxray
chmod +x menu
chmod +x vmess
chmod +x vless
chmod +x trojan
chmod +x shadowsocks
chmod +x shadowsocks2022
chmod +x socks
chmod +x allxray
chmod +x xp
chmod +x dns
chmod +x certxray
chmod +x xraymod
chmod +x xrayofficial
chmod +x about
chmod +x clear-log
chmod +x changer
chmod +x telebot
cd
echo "0 0 * * * root xp" >> /etc/crontab
echo "*/3 * * * * root clear-log" >> /etc/crontab
systemctl restart cron
cat > /root/.profile << END
if [ "$BASH" ]; then
if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi
fi
mesg n || true
clear
menu
END
chmod 644 /root/.profile
clear
echo ""
echo ""
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "                     ${WB}MOD SCRIPT BY DXVPN${NC}                 "
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "  ${WB}»»» Protocol Service «««  |  »»» Network Protocol «««${NC}  "
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "  ${YB}- Vless${NC}                   ${WB}|${NC}  ${YB}- Websocket (CDN) non TLS${NC}"
echo -e "  ${YB}- Vmess${NC}                   ${WB}|${NC}  ${YB}- Websocket (CDN) TLS${NC}"
echo -e "  ${YB}- Trojan${NC}                  ${WB}|${NC}  ${YB}- gRPC (CDN) TLS${NC}"
echo -e "  ${YB}- Socks5${NC}                  ${WB}|${NC}"
echo -e "  ${YB}- Shadowsocks${NC}             ${WB}|${NC}"
echo -e "  ${YB}- Shadowsocks 2022${NC}        ${WB}|${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "               ${WB}»»» Network Port Service «««${NC}             "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "  ${YB}- HTTPS : 443, 2053, 2083, 2087, 2096, 8443${NC}"
echo -e "  ${YB}- HTTP  : 80, 8080, 8880, 2052, 2082, 2086, 2095${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo ""
rm -f install
secs_to_human "$(($(date +%s) - ${start}))"
echo -e "${GB}[ INFO ]${NC} ${YB}Installation Done${NC}"
echo -e "${GB} Script Will Auto reboot in 10 Sec ${NC}"
sleep 10
reboot

