NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
xray_service=$(systemctl status xray | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
nginx_service=$(systemctl status nginx | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ $xray_service == "running" ]]; then
status_xray="${GB}[ ON ]${NC}"
else
status_xray="${RB}[ OFF ]${NC}"
fi
if [[ $nginx_service == "running" ]]; then
status_nginx="${GB}[ ON ]${NC}"
else
status_nginx="${RB}[ OFF ]${NC}"
fi
dtoday="$(vnstat | grep today | awk '{print $2" "substr ($3, 1, 3)}')"
utoday="$(vnstat | grep today | awk '{print $5" "substr ($6, 1, 3)}')"
ttoday="$(vnstat | grep today | awk '{print $8" "substr ($9, 1, 3)}')"
dmon="$(vnstat -m | grep `date +%G-%m` | awk '{print $2" "substr ($3, 1 ,3)}')"
umon="$(vnstat -m | grep `date +%G-%m` | awk '{print $5" "substr ($6, 1 ,3)}')"
tmon="$(vnstat -m | grep `date +%G-%m` | awk '{print $8" "substr ($9, 1 ,3)}')"
domain=$(cat /usr/local/etc/xray/domain)
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
WKT=$(cat /usr/local/etc/xray/timezone)
DATE=$(date -R | cut -d " " -f -4)
MYIP=$(curl -sS ipv4.icanhazip.com)
clear
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "             ${GB}----- [ DXVPN AIO Script ] -----${NC}           "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e " ${CB}Public IP${NC}        ${GB}: $MYIP"
echo -e " ${CB}Service Provider${NC} ${GB}: $ISP"
echo -e " ${CB}Timezone${NC}         ${GB}: $WKT${NC}"
echo -e " ${CB}City${NC}             ${GB}: $CITY${NC}"
echo -e " ${CB}Date${NC}             ${GB}: $DATE${NC}"
echo -e " ${CB}Domain${NC}           ${GB}: $domain${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "     ${GB}NGINX STATUS :${NC} $status_nginx    ${GB}XRAY STATUS :${NC} $status_xray   "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "          ${GB}----- [ Bandwidth Monitoring ] -----${NC}"
echo -e ""
echo -e "  ${GB}Today ($DATE)     Monthly ($(date +%B/%Y))${NC}      "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "    ${CB}↓↓ Down: $dtoday          ↓↓ Down: $dmon${NC}   "
echo -e "    ${CB}↑↑ Up  : $utoday          ↑↑ Up  : $umon${NC}   "
echo -e "    ${CB}≈ Total: $ttoday          ≈ Total: $tmon${NC}   "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "                ${GB}----- [ DXVPN Menu ] -----${NC}              "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e " ${MB}[1]${NC} ${YB}Vmess Menu${NC}          ${MB}[5]${NC} ${YB}Shadowsocks 2022 Menu${NC}"
echo -e " ${MB}[2]${NC} ${YB}Vless Menu${NC}          ${MB}[6]${NC} ${YB}Socks5 Menu${NC}"
echo -e " ${MB}[3]${NC} ${YB}Trojan Menu${NC}         ${MB}[7]${NC} ${YB}All Xray Menu${NC}"
echo -e " ${MB}[4]${NC} ${YB}Shadowsocks Menu${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "                 ${GB}----- [ Utility ] -----${NC}                "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e " ${MB}[8]${NC} ${YB}Log Create Account${NC}  ${MB}[13]${NC} ${YB}DNS Setting${NC}"
echo -e " ${MB}[9]${NC} ${YB}Speedtest${NC}           ${MB}[14]${NC} ${YB}Check DNS Status${NC}"
echo -e " ${MB}[10]${NC} ${YB}Change Domain${NC}      ${MB}[15]${NC} ${YB}Change Xray-core Mod${NC}"
echo -e " ${MB}[11]${NC} ${YB}Renew Cert${NC}         ${MB}[16]${NC} ${YB}Change Xray-core Official${NC}"
echo -e " ${MB}[12]${NC} ${YB}About Script${NC}       ${MB}[17]${NC} ${YB}Telegram Bot${NC}"
echo -e " ${MB}[x]${NC} ${YB}Exit Menu${NC}     "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e ""
read -p " Select Menu :  "  opt
echo -e ""
case $opt in
1) clear ; vmess ;;
2) clear ; vless ;;
3) clear ; trojan ;;
4) clear ; shadowsocks ;;
5) clear ; shadowsocks2022 ;;
6) clear ; socks ;;
7) clear ; allxray ;;
8) clear ; log-create ;;
9) clear ; speedtest ;;
10) clear ; dns ;;
11) clear ; certxray ;;
12) clear ; about ;;
13) clear ; changer ;;
14) clear ;
resolvectl status
echo ""
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
echo ""
echo ""
menu ;;
15) clear ; xraymod ;;
16) clear ; xrayofficial ;;
17) clear ; telebot ;;
x) clear ; exit ;;
*) echo -e "${RB}Wrong Input${NC}" ; sleep 1 ; menu ;;
esac
