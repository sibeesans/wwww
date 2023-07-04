#!/bin/bash
#26/01/2021
clear
clear
# ADDRESSES OF FOLDERS AND FILES

SCPdir="/etc/DXVPN" && [[ ! -d ${SCPdir} ]] && exit 1
SCPusr="${SCPdir}/controller" && [[ ! -d ${SCPusr} ]] && mkdir ${SCPusr}
SCPfrm="${SCPdir}/tools" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
SCPinst="${SCPdir}/protocols" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
SCPlanguage="${SCPdir}/language" && [[ ! -e ${SCPlanguage} ]] && touch ${SCPlanguage}
mkdir -p /etc/BOT &>/dev/null
mkdir -p /etc/BOT-C &>/dev/null
mkdir -p /etc/BOT-A &>/dev/null
mkdir -p /etc/BOT-GEN &>/dev/null
mkdir -p /etc/BOT-C2 &>/dev/null
mkdir -p /etc/BOT-TEMP &>/dev/null
USRdatacredi="/etc/BOT-C2/creditos"

##### PERSONAL TELEGRAM SERVER
[[ $(dpkg --get-selections | grep -w "jq" | head -1) ]] || apt-get install jq -y &>/dev/null
[[ ! -e "/bin/telebot.sh" ]] && wget -O /bin/telebot.sh https://raw.githubusercontent.com/thoiruddin/DXVPN/main/libraries/telebot.sh &>/dev/null
[[ -e /etc/text-bot ]] && rm /etc/text-bot

##### VERIFYING PRIMARY PACKAGES

[[ $(dpkg --get-selections | grep -w "jq" | head -1) ]] || apt-get install jq -y &>/dev/null
[[ $(dpkg --get-selections | grep -w "vnstat" | head -1) ]] || apt-get install vnstat -y &>/dev/null
[[ $(dpkg --get-selections | grep -w "vnstati" | head -1) ]] || apt-get install vnstati -y &>/dev/null
[[ $(dpkg --get-selections | grep -w "nmap" | head -1) ]] || apt-get install nmap -y &>/dev/null

## TOKEN BOT ENTRY
clear
msg -bar
msg -tit
msg -ama "      ## MANAGEMENT BOT | DXVPN  ##  \033[1;31m"
msg -bar
if [[ $1 = "id" || -z $(ps aux | grep -v grep | grep -w "bot.sh" | grep dmS | awk '{print $2}') ]]; then
	[[ -z $2 ]] && echo -ne " \033[1;96m #Enter the BOT Token \033[0;92m \nTOKEN:  \033[0;97m" && read TOKEN || TOKEN="$2"
	[[ -z "$TOKEN" ]] && exit 1                                     #NO TOKENS, NO BOTS
	LANGUAGE="$(cat ${SCPlanguage})" && [[ -z $LANGUAGE ]] && LANGUAGE="en" # ARGUMENT 2 (LANGUAGE)
	[[ -z $3 ]] && echo -ne " \033[1;96m #Enter a name for your User \033[0;92m  \nUSER:  \033[0;97m" && read USERLIB || USERLIB="$3"
	[[ -z "$USERLIB" ]] && exit 1 #USUARIO
	[[ -z $4 ]] && echo -ne " \033[1;96m #Enter a password for your User \033[0;92m  \nPASSWORD:  \033[0;97m" && read PASSLIB || PASSLIB="$4"
	[[ -z "$PASSLIB" ]] && exit 1 #SENHA
	[[ -z $2 ]] && [[ -z $3 ]] && [[ -z $4 ]] && {
		screen -dmS telebot ${SCPfrm}/bot.sh id "$TOKEN" "$USERLIB" "$PASSLIB"
		msg -bar
		echo -e " \033[1;92m                BOT STARTED SUCCESSFULLY"
		msg -bar
		exit 0
	}
else
	kill -9 $(ps aux | grep -v grep | grep -w "bot.sh" | grep dmS | awk '{print $2}') && echo -e " \033[1;91m                BOT STOPPED SUCCESSFULLY"
	msg -bar
	exit 0
fi
LINE='━━━━━━━━━━━━━━━━━━━━'
USRdatabase="/etc/DXVPN/DXVPN-User"
#IMPORTING API
source telebot.sh
TeleBot.init --token "$TOKEN"
TeleBot.username
# SUPPRESS ERRORS
exec 2>/dev/null
# PID SYSTEM
dropbear_pids() {
	unset pids
	port_dropbear=$(ps aux | grep dropbear | awk NR==1 | awk '{print $17;}')
	log=/var/log/auth.log
	loginsukses='Password auth succeeded'
	[[ -z $port_dropbear ]] && return 1
	for port in $(echo $port_dropbear); do
		for pidx in $(ps ax | grep dropbear | grep "$port" | awk -F" " '{print $1}'); do
			pids="${pids}$pidx \n"
		done
	done
	for pid in $(echo -e "$pids"); do
		pidlogs=$(grep $pid $log | grep "$loginsukses" | awk -F" " '{print $3}')
		i=0
		for pidend in $pidlogs; do
			let i++
		done
		if [[ $pidend ]]; then
			login=$(grep $pid $log | grep "$pidend" | grep "$loginsukses")
			PID=$pid
			user=$(echo $login | awk -F" " '{print $10}' | sed -r "s/'//g")
			waktu=$(echo $login | awk -F" " '{print $2"-"$1,$3}')
			[[ -z $user ]] && continue
			echo "$user|$PID|$waktu"
		fi
	done
}
openvpn_pids() {
	#nome|#loguin|#rcv|#snd|#time
	byte() {
		while read B dummy; do
			[[ "$B" -lt 1024 ]] && echo "${B} bytes" && break
			KB=$(((B + 512) / 1024))
			[[ "$KB" -lt 1024 ]] && echo "${KB} Kb" && break
			MB=$(((KB + 512) / 1024))
			[[ "$MB" -lt 1024 ]] && echo "${MB} Mb" && break
			GB=$(((MB + 512) / 1024))
			[[ "$GB" -lt 1024 ]] && echo "${GB} Gb" && break
			echo $(((GB + 512) / 1024)) terabytes
		done
	}
	for user in $(mostrar_usuarios); do
		[[ ! $(sed -n "/^${user},/p" /etc/openvpn/openvpn-status.log) ]] && continue
		i=0
		unset RECIVED
		unset SEND
		unset HOUR
		while read line; do
			IDLOCAL=$(echo ${line} | cut -d',' -f2)
			RECIVED+="$(echo ${line} | cut -d',' -f3)+"
			SEND+="$(echo ${line} | cut -d',' -f4)+"
			DATESEC=$(date +%s --date="$(echo ${line} | cut -d',' -f5 | cut -d' ' -f1,2,3,4)")
			TIMEON="$(($(date +%s) - ${DATESEC}))"
			MIN=$(($TIMEON / 60)) && SEC=$(($TIMEON - $MIN * 60)) && HOR=$(($MIN / 60)) && MIN=$(($MIN - $HOR * 60))
			HOUR+="${HOR}h:${MIN}m:${SEC}s \n"
			let i++
		done <<<"$(sed -n "/^${user},/p" /etc/openvpn/openvpn-status.log)"
		RECIVED=$(echo $(echo ${RECIVED}0 | bc) | byte)
		SEND=$(echo $(echo ${SEND}0 | bc) | byte)
		HOUR=$(echo -e $HOUR | sort -n | tail -1)
		echo -e "$user|$i|$RECIVED|$SEND|$HOUR"
	done
}
# ADD USER
add_user() {
	# name password limit days
	[[ $(cat /etc/passwd | grep $1: | grep -vi [a-z]$1 | grep -v [0-9]$1 >/dev/null) ]] && return 1
	valid=$(date '+%C%y-%m-%d' -d " +$3 days") && datexp=$(date "+%F" -d " + $3 days")
	useradd -M -s /bin/false $1 -e ${valid} >/dev/null 2>&1 || return 1
	(
		echo $2
		echo $2
	) | passwd $1 2>/dev/null || {
		userdel --force $1
		return 1
	}
	[[ -e ${USRdatabase} ]] && {
		newbase=$(cat ${USRdatabase} | grep -w -v "$1")
		echo "$1|$2|${datexp}|$4" >${USRdatabase}
		for value in $(echo ${newbase}); do
			echo $value >>${USRdatabase}
		done
	} || echo "$1|$2|${datexp}|$4" >${USRdatabase}
}
# REMOVE USER
rm_user() {
	#name
	userdel --force "$1" &>/dev/null || return 1
	[[ -e ${USRdatabase} ]] && {
		newbase=$(cat ${USRdatabase} | grep -w -v "$1")
		rm ${USRdatabase} && touch ${USRdatabase}
		for value in $(echo ${newbase}); do
			echo $value >>${USRdatabase}
		done
	}
}
# LIST REGISTERED USERS
mostrar_usuarios() {
	for u in $(awk -F : '$3 > 900 { print $1 }' /etc/passwd | grep -v "nobody" | grep -vi polkitd | grep -vi system-); do
		echo "$u"
	done
}
# DEFINE AN IP
meu_ip() {
	if [[ -e /etc/DXVPN/DXVPN-VPS ]]; then
		echo "$(cat /etc/DXVPN/DXVPN-VPS)"
	else
		MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127 \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | grep -o -E '[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | head -1)
		MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
		[[ "$MEU_IP" != "$MEU_IP2" ]] && echo "$MEU_IP2" || echo "$MEU_IP"
		echo "$MEU_IP" >/etc/DXVPN/DXVPN-VPS
	fi
}
# USER BLOCK
blockfun() {
	local bot_return="$LINE \n"
	bot_return+="--❌ YOU CANNOT USE THE BOT ❌-- \n"
	bot_return+="$LINE \n"
	bot_return+="_--If you are ADMIN enter your credentials--_ \n"
	bot_return+="$LINE \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "$(echo -e $bot_return)" \
	--parse_mode markdown
	return 0
}
# LOGIN SYSTEM
ativarid_fun() {
	if [[ ! -z $LIBERADOS ]] && [[ $(echo ${LIBERADOS} | grep -w "$3") ]]; then
		local bot_return+="$LINE \n"
		bot_return+="- - 🔰 ADMIN ACCESS RELEASED 🔰 - -  \n"
		bot_return+="$LINE \n"
		bot_return+="✌️ You can now use the bot \n"
		bot_return+="👉 Use it for good \n"
		bot_return+="⚙️ Main Command: * /menu * \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	elif [[ $1 = ${USERLIB} ]] && [[ $2 = ${PASSLIB} ]]; then
		[[ -z $LIBERADOS ]] && LIBERADOS="${3}" || LIBERADOS="${LIBERADOS} ${3}"
		local bot_return+="$LINE \n"
		bot_return+="- - 🔰 ADMIN ACCESS RELEASED 🔰 - -  \n"
		bot_return+="$LINE \n"
		bot_return+="✌️ You can now use the bot \n"
		bot_return+="👉 Use it for good \n"
		bot_return+="⚙️ Main Command: * /menu * \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	else
		local bot_return+="$LINE \n"
		bot_return+="--❌ ADMIN CREDENTIALS ERROR ❌-- \n"
		bot_return+="$LINE \n"
		bot_return+="_ADMIN Access Denied_ \n"
		bot_return+="_Wrong User/Password_ \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	fi
}
loguin_fun() {
	local bot_return+="$LINE \n"
	bot_return+="USERS WITH ADMIN ACCESS \n"
	bot_return+="$LINE \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "$(echo -e $bot_return)" \
	--parse_mode markdown
	for lines in $(echo $LIBERADOS); do
		local bot_return+="$LINE \n"
		bot_return2+="$Usuario ID: $lines \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return2)" \
		--parse_mode markdown
	done
	return 0
}
# VPS INFO
infovps() {
	mine_port() {
		unset portas
		portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN")
		i=0
		while read port; do
			var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
			[[ "$(echo -e ${portas} | grep "$var1|$var2")" ]] || {
				portas+="$var1|$var2 \n"
				let i++
			}
		done <<<"$portas_var"
		echo -e $portas
	}
	local bot_return="$LINE \n"
	bot_return+="*Active Ports and Protocols* \n"
	bot_return+="$LINE \n"
	bot_return+="*IP:* $(meu_ip) \n"
	while read line; do
		local serv=$(echo $line | cut -d'|' -f1)
		local port=$(echo $line | cut -d'|' -f2)
		bot_return+="*Service:* ${serv} *Puerto:* ${port} \n"
	done <<<"$(mine_port)"
	bot_return+="$LINE \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "$(echo -e $bot_return)" \
	--parse_mode markdown
	return 0
}
# HELP
ajuda_fun() {

	#MONITOR UDP
	on=" [ ENABLED ] " && off=" [ DISABLED ] "
	[[ $(ps x | grep badvpn | grep -v grep | awk '{print $1}') ]] && badvpn=$on || badvpn=$off

	#REGISTERED SSH ACCOUNTS
	SSHN="$(grep -c home /etc/passwd)"
	SSH2="$(echo ${SSHN} | bc)-2"
	echo "${SSH2}" | bc >/etc/BOT-A/SSH20.log
	SSH3="$(less /etc/BOT-A/SSH20.log)"
	SSH4="$(echo $SSH3)"
	#ONLINES
	ONLINES="$(less /etc/DXVPN/USER-Onlines)"
	## DEMOS REGISTERED
	demo=$(cd /etc/BOT-TEMP && ls | wc -l)
	cd
	##DEMOS REMAINING
	demo2="10-$(echo ${demo} | bc)+0"
	echo "${demo2}" | bc >/etc/BOT-A/SSH-DEMO.log
	demo3="$(less /etc/BOT-A/SSH-DEMO.log)"
	demor="$(echo $demo3)"

	local bot_return="*$LINE* \n"
	bot_return+="*🔰 MANAGER DXVPN 1.0 🔰* \n"
	bot_return+="$LINE \n"
	bot_return+="_▪️ SSH REGISTERED:_ ( *$SSH4* ) \n"
	bot_return+="_▪️ CONNECTED:_ ( *$ONLINES* ) \n"
	bot_return+="_▪️ BADVPN:_ 🎮 *$badvpn*  \n"
	bot_return+="$LINE \n"
	bot_return+=" _AVAILABLE COMMANDS_ \n"
	bot_return+="---------------------------------- \n"
	bot_return+="/agregar -->> Add User \n"
	[[ $(dpkg --get-selections | grep -w "openvpn" | head -1) ]] && [[ -e /etc/openvpn/openvpn-status.log ]] && bot_return+="/openadd ($(fun_trans "crear archivo openvpn")) \n"
	bot_return+="/remove -->> Remove User \n"
	bot_return+="/renew -->> Renew Account \n"
	bot_return+="/users -->> User Info \n"
	bot_return+="/viewblocked -->> Blocked Users \n"
	bot_return+="/block -->> Block User \n"
	bot_return+="/unblock -->> Unblock user \n"
	bot_return+="/online -->> Online Users \n"
	bot_return+="/backup -->> Backup-User \n"
	bot_return+="/restorebackup -->> Restore Backup \n"
	bot_return+="/infovps -->> Server Info \n"
	bot_return+="$LINE \n"
	bot_return+=" _ TOOLS _ \n"
	bot_return+="---------------------------------- \n"
	bot_return+="/lang -->> Translate Text \n"
	bot_return+="/scan -->> Subdomain Scan \n"
	bot_return+="/generate -->> Encode and Decode Text \n"
	bot_return+="/sshi -->> SSH account information \n"
	bot_return+="/admins -->> ADMIN's with Access \n"
	bot_return+="$LINE \n"
	bot_return+="/ADMIN -->> Release the bot \n"
	bot_return+="$LINE \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "$(echo -e $bot_return)" \
	--parse_mode markdown
	return 0
}
info_fun() {
	if [[ ! -e "${USRdatabase}" ]]; then
		local bot_return="$LINE \n"
		bot_return="A database with users has not been identified \n"
		bot_return="The Users to Follow Does not contain any information \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
	else
		VPSsec=$(date +%s)
		local bot_return="$LINE \n"
		bot_return+="* Registered SSH Accounts*  \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		for user in $(mostrar_usuarios); do
			sen=$(cat ${USRdatabase} | grep -w "$user" | cut -d '|' -f2)
			[[ -z $sen ]] && sen="???"
			DateExp="$(cat ${USRdatabase} | grep -w "${user}" | cut -d'|' -f3)"
			if [[ ! -z $DateExp ]]; then
				DataSec=$(date +%s --date="$DateExp")
				[[ "$VPSsec" -gt "$DataSec" ]] && EXPTIME="${red}[Exp]" || EXPTIME="${gren}[$(($(($DataSec - $VPSsec)) / 86400))]"
			else
				EXPTIME="???"
			fi
			limit=$(cat ${USRdatabase} | grep -w "$user" | cut -d '|' -f4)
			[[ -z $limit ]] && limit="???"
			bot_return="$LINE \n"
			bot_return+="$(fun_trans "User"): $user \n"
			bot_return+="$(fun_trans "Password"): $sen \n"
			bot_return+="$(fun_trans "Remaining days"): $EXPTIME \n"
			bot_return+="$(fun_trans "Limit"): $limit \n"
			bot_return+="$LINE \n"
			TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
			--text "$(echo -e $bot_return)" \
			--parse_mode markdown
		done
	fi
	return 0
}
online_fun() {
	MyTIME="${SCPusr}/time-DXVPN"
	[[ -e ${MyTIME} ]] && source ${MyTIME} || touch ${MyTIME}
	local bot_return="$LINE \n"
	bot_return+="$* User Monitor*  \n"
	bot_return+="$LINE \n"
	while read user; do
		PID="0+"
		[[ $(dpkg --get-selections | grep -w "openssh" | head -1) ]] && PID+="$(ps -u $user | grep sshd | wc -l)+"
		[[ $(dpkg --get-selections | grep -w "dropbear" | head -1) ]] && PID+="$(dropbear_pids | grep -w "${user}" | wc -l)+"
		[[ $(dpkg --get-selections | grep -w "openvpn" | head -1) ]] && [[ -e /etc/openvpn/openvpn-status.log ]] && [[ $(openvpn_pids | grep -w "$user" | cut -d'|' -f2) ]] && PID+="$(openvpn_pids | grep -w "$user" | cut -d'|' -f2)+"
		PID+="0"
		[[ $(echo $PID | bc) = 0 ]] && continue
		TIMEON="${TIMEUS[$user]}"
		[[ -z $TIMEON ]] && TIMEON=0
		MIN=$(($TIMEON / 60))
		SEC=$(($TIMEON - $MIN * 60))
		HOR=$(($MIN / 60))
		MIN=$(($MIN - $HOR * 60))
		HOUR="${HOR}h:${MIN}m:${SEC}s"
		[[ -z $(cat ${USRdatabase} | grep -w "${user}") ]] && MAXPID="?" || MAXPID="$(cat ${USRdatabase} | grep -w "${user}" | cut -d'|' -f4)"
		TOTALPID="$(echo $PID | bc)/$MAXPID"
		local IMPRIME="YES"
		local bot_return+="$LINE \n"
		bot_return="$(fun_trans "User"): $user \n"
		bot_return+="$(fun_trans "Connections"): $TOTALPID \n"
		bot_return+="$(fun_trans "Total Time"): $HOUR \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
	done <<<"$(mostrar_usuarios)"
	[[ -z $IMPRIME ]] && {
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "No users online") \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	}
}
useradd_fun() {
	error_fun() {
		local bot_return="$LINE \n"
		bot_return+=" -->>> MODE OF USE \n"
		bot_return+="$LINE \n"
		bot_return+="Add User Password Days Limit \n"
		bot_return+="Example: \n"
		bot_return+='add admin admin 30 1 \n'
		bot_return+="$LINE \n"
		case $1 in
		[1-3] | 14)
			[[ $1 = 1 ]] && bot_return+="$(fun_trans "Null User")" && bot_return+="$LINE \n"
			[[ $1 = 2 ]] && bot_return+="$(fun_trans "User With Very Short Name")" && bot_return+="$LINE \n"
			[[ $1 = 3 ]] && bot_return+="$(fun_trans "User With Very Big Name")" && bot_return+="$LINE \n"
			[[ $1 = 14 ]] && bot_return+="$(fun_trans "User already exists")" && bot_return+="$LINE \n"
			;;
		[4-6])
			[[ $1 = 4 ]] && bot_return+="$(fun_trans "Null Password")" && bot_return+="$LINE \n"
			[[ $1 = 5 ]] && bot_return+="$(fun_trans "Very Short Password")" && bot_return+="$LINE \n"
			[[ $1 = 6 ]] && bot_return+="$(fun_trans "Very Large Password")" && bot_return+="$LINE \n"
			;;
		[7-9])
			[[ $1 = 7 ]] && bot_return+="$(fun_trans "Null Duration")" && bot_return+="$LINE \n"
			[[ $1 = 8 ]] && bot_return+="$(fun_trans "Invalid duration use numbers")" && bot_return+="$LINE \n"
			[[ $1 = 9 ]] && bot_return+="$(fun_trans "Maximum duration of one year")" && bot_return+="$LINE \n"
			;;
		1[1-3])
			[[ $1 = 11 ]] && bot_return+="$(fun_trans "Null Limit")" && bot_return+="$LINE \n"
			[[ $1 = 12 ]] && bot_return+="$(fun_trans "Invalid limit use numbers")" && bot_return+="$LINE \n"
			[[ $1 = 13 ]] && bot_return+="$(fun_trans "Maximum limit of 999")" && bot_return+="$LINE \n"
			;;
		esac
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
	}
	usuarios_ativos=($(mostrar_usuarios))
	[[ -z "$1" ]] && error_fun && return 0
	[[ -z "$2" ]] && error_fun && return 0
	[[ -z "$3" ]] && error_fun && return 0
	[[ -z "$4" ]] && error_fun && return 0
	if [[ -z $1 ]]; then
		error_fun 1 && return 0
	elif [[ "${#1}" -lt "4" ]]; then
		error_fun 2 && return 0
	elif [[ "${#1}" -gt "24" ]]; then
		error_fun 3 && return 0
	elif [[ "$(echo ${usuarios_ativos[@]} | grep -w "$1")" ]]; then
		error_fun 14 && return 0
	fi
	if [[ -z $2 ]]; then
		error_fun 4 && return 0
	elif [[ "${#2}" -lt "6" ]]; then
		error_fun 5 && return 0
	elif [[ "${#2}" -gt "20" ]]; then
		error_fun 6 && return 0
	fi
	if [[ -z "$3" ]]; then
		error_fun 7 && return 0
	elif [[ "$3" != +([0-9]) ]]; then
		error_fun 8 && return 0
	elif [[ "$3" -gt "360" ]]; then
		error_fun 9 && return 0
	fi
	if [[ -z "$4" ]]; then
		error_fun 11 && return 0
	elif [[ "$4" != +([0-9]) ]]; then
		error_fun 12 && return 0
	elif [[ "$4" -gt "999" ]]; then
		error_fun 13 && return 0
	fi
	add_user "$1" "$2" "$3" "$4"
	if [[ "$?" = "1" ]]; then
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "User Was Not Created") \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	else
		local bot_return="$LINE \n"
		bot_return+="ACCOUNT CREATED \n"
		bot_return+="$LINE \n"
		bot_return+="User: $1 \n"
		bot_return+="Password: $2 \n"
		bot_return+="Duration: $3 Dias \n"
		bot_return+="Limit: $4 Logeo \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	fi
}
userdell_fun() {
	error_fun() {
		local bot_return="$LINE \n"
		bot_return+=" -->>> MODE OF USE \n"
		bot_return+="$LINE \n"
		bot_return+="delete user \n"
		bot_return+="Example: \n"
		bot_return+='delete admin \n'
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	}
	[[ -z "$1" ]] && error_fun && return 0
	rm_user "$1" && {
		local bot_return="$LINE \n"
		bot_return+="$Removed Successfully \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	} || {
		local bot_return="$LINE \n"
		bot_return+="User Not Removed \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	}
}
paygen_fun() {
	generate_pays() {
		echo 'GET http://mhost/ HTTP/1.1[crlf][raw][crlf] [crlf][crlf]
 CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]
 CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf] [crlf]
 CONNECT [host_port]@mhost HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]
 CONNECT [host_port]@mhost HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT [host_port]@mhost [protocol][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT [host_port]@mhost [protocol][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
 CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf][crlf]
 CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf] [crlf]
 CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Referer: mhost[crlf][crlf]
 CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Referer: mhost[crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
 GET mhost@[host_port] [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]
 GET mhost@[host_port] [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf] [crlf]
 GET [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]
 GET [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf] [crlf]
 CONNECT [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
 CONNECT [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][raw][crlf] [crlf]
 CONNECT [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][crlf]
 CONNECT [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]User-Agent: [ua][crlf][crlf][split][raw][crlf][crlf]CONNECT mhost:443 HTTP/1.1[crlf][raw][crlf][crlf]GET http://mhost/ HTTP/1.0[crlf]Host: mhost[crlf]Proxy-Authorization: basic: mhost[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive [crlf]Host: [host][crlf][crlf][split][raw][crlf][crlf]GET http://mhost/ HTTP/1.0[crlf]Host: mhost/[crlf][crlf]CONNECT [host_port] HTTP/1.0[crlf][crlf][realData][crlf][crlf]
 [method] mhost:443 HTTP/1.1[crlf][raw][crlf][crlf]GET http://mhost/ HTTP/1.1 \nHost: mhost \nConnection: close \nConnection: close \nUser-Agent:[ua][crlf]Proxy-Connection: Keep-Alive[crlf]Host: [host][crlf][crlf][delay_split][raw][crlf][crlf][raw][crlf][realData][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]User-Agent: KDDI[crlf]Host: [host][crlf][crlf][raw][raw][crlf][raw][crlf][raw][crlf][crlf]DELETE http://mhost/ HTTP/1.1[crlf]Host: m.opera.com[crlf]Proxy-Authorization: basic: *[crlf]User-Agent: KDDI[crlf]Connection: close[crlf]Proxy-Connection: Direct[crlf]Host: [host][crlf][crlf][raw][raw][crlf][crlf][raw][method] http://mhost[port] HTTP/1.1[crlf]Host: [host][crlf][crlf]CONNECT [host] [protocol][crlf][crlf][CONNECT [host] [protocol][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][netData][crlf][instant_split]MOVE http://mhost[delay_split][crlf][crlf][netData][crlf][instant_split]MOVE http://mhost[delay_split][crlf][crlf][netData][crlf][instant_split]MOVE http://mhost[delay_split][crlf][crlf]X-Online-Host: mhost[crlf]Packet Length: Authorization[crlf]Packet Content: Authorization[crlf]Transfer-Encoding: chunked[crlf]Referer: mhost[crlf][crlf]
 [crlf][crlf]CONNECT [host_port]@mhost/ [protocol][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: [ua][crlf]CONNECT [host]@mhost/ [protocol][crlf][crlf]
 [method] [host_port] [protocol] [delay_split]GET http://mhost/ HTTP/1.1[netData][crlf]GET mip:80[crlf]X-GreenArrow-MtaID: smtp1-1[crlf]CONNECT http://mhost/ HTTP/1.1[crlf]CONNECT http://mhost/ HTTP/1.0[crlf][split]CONNECT http://mhost/ HTTP/1.1[crlf]CONNECT http://mhost/ HTTP/1.1[crlf][crlf][method] [host_port] [protocol]?[split]GET http://mhost:8080/[crlf][crlf]GET [host_port] [protocol]?[split]OPTIONS http://mhost/[crlf]Connection: Keep-Alive[crlf]User-Agent: Mozilla/5.0 (Android; Mobile; rv:35.0) Gecko/35.0 Firefox/35.0[crlf]CONNECT [host_port] [protocol] [crlf]GET [host_port] [protocol]?[split]GET http://mhost/[crlf][crlf][method] mip:80[split]GET mhost/[crlf][crlf]: Cache-Control:no-store,no-cache,must-revalidate,post-check=0,pre-check=0[crlf]Connection:close[crlf]CONNECT [host_port] [protocol]?[split]GET http://mhost:/[crlf][crlf]POST [host_port] [protocol]?[split]GET[crlf]mhost:/[crlf]Content-Length: 999999999 \r \n \r \n
 GET [host_port] [protocol][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Referer: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
 CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET mhost/ HTTP/1.1[crlf][crlf]
 CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: navegue.vivo.ddivulga.com/pacote[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost/[crlf]GET mhost/ HTTP/1.1[crlf]HEAD mhost/ HTTP/1.1[crlf]TRACE mhost/ HTTP/1.1[crlf]OPTIONS mhost/ HTTP/1.1[crlf]PATCH mhost/ HTTP/1.1[crlf]PROPATCH mhost/ HTTP/1.1[crlf]DELETE mhost/ HTTP/1.1[crlf]PUT mhost/ HTTP/1.1[crlf]Host: mhost/[crlf]Host: mhost/[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]X-Forwarded-For: mhost[protocol][crlf][crlf]
 [raw][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost/[crlf]X-Forward-Host: mhost/[crlf]Connection: Keep-Alive[crlf]Connection: Close[crlf]User-Agent: [ua][crlf][crlf]
 [raw][split]GET mhost/ HTTP/1.1[crlf] [crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]GET mhost/[crlf]Connection: close Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][raw][crlf][crlf]
 [raw]split]GET mhost/ HTTP/1.1[crlf][crlf]
 GET [host_port] [protocol][instant_split]GET http://mhost/ HTTP/1.1[crlf]
 GET [host_port] [protocol][crlf][delay_split]CONNECT http://mhost/ HTTP/1.1[crlf]
 CONNECT [host_port] [protocol] [instant_split]GET http://mhost/ HTTP/1.1[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]User-Agent: [ua][crlf][crlf]
 GET http://mhost/ HTTP/2.0[auth][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]CONNECT [host_port] [protocol] [auth][crlf][crlf][delay_split][raw][crlf]JAZZ http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf][delay_split]CONNECT [host_port] [protocol] [method][crlf] [crlf][crlf]
 CONNECT [host_port] [protocol][crlf]GET http://mhost/ HTTP/1.1 \rHost: mhost \r[crlf]X-Online-Host: mhost \r[crlf]X-Forward-Host: mhost \rUser-Agent: Mozilla/5.0 (X11; U; Linux x86_64; en-gb) AppleWebKit/534.35 (KHTML, like Gecko) Chrome/11.0.696.65 Safari/534.35 Puffin/2.9174AP[crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost/ [crlf]User-Agent: Yes[crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive[crlf][crlf][raw][crlf][crlf]
 GET [host_port] [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][raw][crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]UseDNS: Yes[crlf]Cache-Control: no-cache[crlf][raw][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf] Access-Control-Allow-Credentials: true, true[crlf] Access-Control-Allow-Headers: X-Requested-With,Content-Type, X-Requested-With,Content-Type[crlf]  Access-Control-Allow-Methods: GET,PUT,OPTIONS,POST,DELETE, GET,PUT,OPTIONS,POST,DELETE[crlf]  Age: 8, 8[crlf] Cache-Control: max-age=86400[crlf] public[crlf] Connection: keep-alive[crlf] Content-Type: text/html; charset=UTF-8[crlf]Content-Length: 9999999999999[crlf]UseDNS: Yes[crlf]Vary: Accept-Encoding[crlf][raw][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf] Access-Control-Allow-Credentials: true, true[crlf] Access-Control-Allow-Headers: X-Requested-With,Content-Type, X-Requested-With,Content-Type[crlf]  Access-Control-Allow-Methods: GET,PUT,OPTIONS,POST,DELETE, GET,PUT,OPTIONS,POST,DELETE[crlf]  Age: 8, 8[crlf] Cache-Control: max-age=86400[crlf] public[crlf] Connection: keep-alive[crlf] Content-Type: text/html; charset=UTF-8[crlf]Content-Length: 9999999999999[crlf]Vary: Accept-Encoding[crlf][raw][crlf] [crlf][crlf]
 [netData][split][raw][crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost/[crlf]User-Agent: Yes[crlf]Connection: close[crlf]Proxy-Connection: update[crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]host: http://mhost/[crlf]Connection: close update[crlf]User-Agent: [ua][crlf][crlf][raw][crlf][crlf] [crlf]
 [raw][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][raw][crlf][crlf]User-Agent: [ua][crlf]Connection: Close[crlf]Proxy-connection: Close[crlf]Proxy-Authorization: Basic[crlf]Cache-Control: no-cache[crlf]Connection: Keep-Alive[crlf][raw][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Content-Type: text/html; charset=iso-8859-1[crlf]Connection: close[crlf][crlf]User-Agent: [ua][crlf][crlf]Referer: mhost[crlf]Cookie: mhost[crlf]Proxy-Connection: Keep-Alive [crlf][crlf][raw][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Upgrade-Insecure-Requests: 1[crlf]User-Agent: Mozilla/5.0 (Linux; Android 5.1; LG-X220 Build/LMY47I) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.83 Mobile Safari/537.36[crlf]Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8[crlf]Referer: http://mhost[crlf]Accept-Encoding: gzip, deflate, sdch[crlf]Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4[crlf]Cookie: _ga=GA1.2.2045323091.1494102805; _gid=GA1.2.1482137697.1494102805; tfp=80bcf53934df3482b37b54c954bd53ab; tpctmp=1494102806975; pnahc=0; _parsely_visitor={%22id%22:%22719d5f49-e168-4c56-b7c7-afdce6daef18%22%2C%22session_count%22:1%2C%22last_session_ts%22:1494102810109}; sc_is_visitor_unique=rx10046506.1494105143.4F070B22E5E94FC564C94CB6DE2D8F78.1.1.1.1.1.1.1.1.1[crlf][crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive[crlf][netData][crlf] [crlf][crlf]
 GET [host_port] [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][raw][crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control: no-cache[crlf][raw][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: [ua][crlf]Connection: close [crlf]Referer:http://mhost[crlf]Content-Type: text/html; charset=iso-8859-1[crlf]Content-Length:0[crlf]Accept: text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5[crlf][raw][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: null[crlf]Connection: close[crlf]Proxy-Connection: x-online-host[crlf][crlf] CONNECT [host_port] [protocol] [netData][crlf]Content-Length: 130 [crlf][crlf]
 [raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf][crlf]User-Agent: Yes[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Connection: Basic[crlf]Referer: mhost[crlf]Cookie: mhost/ [crlf]Proxy-Connection: Keep-Alive[crlf][crlf][netData][crlf] [crlf][crlf]
 [raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Accept-Language: en-us,en;q=0.5[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Keep-Alive: 115[crlf]Connection: keep-alive[crlf]Referer: mhost[crlf]Cookie: mhost/ Proxy-Connection: Keep-Alive[crlf][crlf][netData][crlf] [crlf][crlf]
 [raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control: no-cache[crlf][raw][crlf] [crlf]
 [raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf][crlf][raw][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]CONNECT [host_port][method]HTTP/1.1[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost[crlf][crlf]DELETE http://mhost/ HTTP/1.1[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][method] [host_port]@mip [crlf][crlf]http://mhost/ HTTP/1.1[crlf]mip[crlf][crlf] [crlf][crlf]http://mhost/ HTTP/1.1[crlf]Host@mip[crlf][crlf] [crlf][crlf] http://mhost/ HTTP/1.1[crlf]Host mhost/[crlf][crlf][netData][crlf] [crlf][crlf] http://mhost/ HTTP/1.1[crlf] [crlf][crlf][netData][crlf] [crlf][crlf] http://mhost/ HTTP/1.1[cr][crlf] [crlf][crlf][netData][cr][crlf] [crlf][crlf]CONNECT mip:22@http://mhost/ HTTP/1.1[crlf] [crlf][crlf][netData][crlf] [crlf][crlf]
 CONNECT [host_port]@mhost/ HTTP/1.1[crlf][crlf]CONNECT http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: close[crlf]User-Agent: [ua][crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control : no-cache[crlf][crlf]
 CONNECT [host_port]@mhost/ HTTP/1.0[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: close[crlf]User-Agent: [ua][crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control : no-cache[crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13[crlf]Accept-Language: en-us,en;q=0.5[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Keep-Alive: 115[crlf]Connection: keep-alive[crlf]Referer: mhost[crlf]Cookie: mhost/ Proxy-Connection: Keep-Alive [crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: Yes[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Connection: Basic[crlf]Referer: mhost[crlf]Cookie: mhost/ [crlf]Proxy-Connection: Keep-Alive[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][delay_split]CONNECT [host_port]@mhost/ [protocol][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]DATA: 2048B[crlf]Host: mhost[crlf]User-Agent: Yes[crlf]Connection: close[crlf]Accept-Encoding: gzip[crlf]Non-Buffer: true[crlf]Proxy: false[crlf][crlf][netData][crlf] [crlf][crlf]
 GET [host_port] [protocol][crlf][delay_split]CONNECT http://mhost/ HTTP/1.1[crlf]Host: http://mhost/[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: http://mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Cache-Control=max-age=0[crlf][crlf][raw][crlf] [crlf][crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf]X-Online-Host: mhost[crlf][crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Referer: mhost[crlf]GET /HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf][raw][crlf]Referer: mhost[crlf][crlf]
 GET http://mhost/ HTTP/1.1[cr][crlf]Host: mhost/ \nUser-Agent: Yes \nConnection: close \nProxy-Connection: Keep-Alive \n \r \n \r \n[netData] \r \n  \r \n \r \n
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: close Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][split]CONNECT mhost@[host_port] [protocol][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][realData][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]CONNECT mhost/ [protocol][crlf][crlf]
 [raw][crlf]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]CONNECT mhost/ [protocol][crlf]
 [raw] HTTP/1.0 \r \n \r \nGET http://mhost/ HTTP/1.1 \r \nHost: mhost \r \nConnection: Keep-Alive \r \nCONNECT mhost \r \n \r \n
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][raw][crlf][crlf]
 GET [host_port]@mhost/ HTTP/1.1[crlf]X-Real-IP:mip[crlf]X-Forwarded-For:http://mhost/ http://mhost/[crlf]X-Forwarded-Port:mhost[crlf]X-Forwarded-Proto:http[crlf]Connection:Keep-Alive[crlf][crlf][instant_split][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host:mhost[crlf][crlf][split][realData][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][realData][crlf]CONNECT mhost/ HTTP/1.1[crlf][crlf]
 CONNECT [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
 [raw][crlf]GET http://mhost/ [protocol][crlf][split]mhost:/ HTTP/1.1[crlf]Host: mhost:[crlf]X-Forward-Host: mhost:[crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Connection: close[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host:http://mhost[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1 \r \nHost: mhost \r \n \r \n[netData] \r \n \r \n \r \n
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][realData][crlf][crlf]
 GET http://mhost/ HTTP/1.1 \r \nX-Online-Host:mhost \r \n \r \nCONNECT mip:443[crlf]HTTP/1.0 \r \n  \r \n \ \r \n \r \n \ \r \n \r \n \ \r \n \r \n \ \r \n \r \n \ \ \r \n
 GET http://mhost/ HTTP/1.1 \r \nGET: mhost \n \r \nCONNECT mip:443[crlf]HTTP/1.0 \r \n  \r \n \ \r \n \r \n \ \r \n \r \n \ \r \n \r \n \ \r \n \r \n \ \ \r \n
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: close[crlf][raw][crlf] [crlf][crlf]
 GET http://mhost/[crlf]X-Forward-Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf]X-Forward-Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf]CONNECT mhost/ [protocol][crlf] [crlf][crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]mhost[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]Forward-Host: mhost[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]Connection: http://mhost[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]CONNECT mhost@[host_port] [protocol][crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]Connection: Keep-Alive[crlf]mhost@[host_port][crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf][netdata][crlf] [crlf]GET mhost/ [protocol][crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf][crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf][split]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf][crlf]User-Agent: [ua][crlf]Connection: close[crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf][raw][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][raw][crlf] [crlf][crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]CONNECT http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
 GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]Connection: close[crlf][netData][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]CONNECT http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]Connection: close[crlf][netdata][crlf] [crlf][split]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][netData][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][netData][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]mhost \r \nHost:mhost \r \n \r \n[netData] \r \n  \r \n \r \n
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf][realData][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]CONNECT mhost/  [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]host: mhost[crlf][crlf][realData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost/ [crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][raw][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][realData][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf]CONNECT mhost/ [protocol][crlf] [crlf]
 GET http://mhost/ HTTP/1.1[crlf]mhost[crlf]Host: mhost[crlf][crlf]CONNECT mhost/ [crlf][raw][crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]mhost[crlf]Host: mhost[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf]CONNECT [host_port][crlf]CONNECT mhost/ [crlf][crlf][cr]
 [realData][crlf][split]GET http://mhost/  HTTP/1.1[crlf][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]mhost[crlf]Host: mhost[crlf][crlf]CONNECT [host_port][crlf]GET mhost/ [crlf]
 CONNECT [host_port]@mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Forward-Host: mhost[crlf][raw][crlf][crlf]
 [raw][crlf][cr][crlf]X-Online-Host: mhost[crlf]Connection: [crlf]User-Agent: [ua][crlf]Content-Lenght: 99999999999[crlf][crlf]
 [raw][crlf]X-Online-Host: mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][raw][crlf]X-Online-Host: mhost[crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Authorization: Basic: Connection: X-Forward-Keep-AliveX-Online-Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]host:frontend.claro.com.br[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][raw][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: Multibanco.com.br[crlf][crlf][raw][crlf] [crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Host: mhost/ [crlf][crlf][raw][crlf]CONNECT [crlf]
 GET http://mhost/ HTTP/1.1[crlf] Proxy-Authorization: Basic:Connection: X-Forward-Keep-AliveX-Online-Host:[crlf][crlf][netData][crlf] [crlf][crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost[crlf][crlf]
 [raw][crlf]X-Online-Host: mhost[crlf][crlf][raw][crlf]X-Online-Host: mhost/ [crlf][crlf]
 [raw][crlf]X-Online-Host: http://mhost[crlf][crlf]CONNECT[host_port] [protocol][crlf]X-Online-Host: mhost/ [crlf][crlf]
 CONNECT [host_port]@mhost/ HTTP/1.1[crlf]CONNECT mip:443 [crlf][crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost[crlf][crlf][split]GET mhost/ HTTP/1.1[cr][crlf][raw][crlf] [crlf][crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host:mhost[crlf][crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]
 GET http://mhost/ HTTP/1.1[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf]GET mip:443@mhost/ HTTP/1.1[crlf][crlf]
 CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost/ User-Agent: Yes[crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive Connection: Transfer-Encoding[crlf] [protocol][crlf]User-Agent: [ua][crlf][raw][auth][crlf][crlf][netData][crlf] [crlf][crlf]
 [raw][crlf]Host: mhost[crlf]GET http://mhost/ HTTP/1.1[crlf]X-Online-Host: mhost[crlf][crlf]' >$HOME/$1
	}
	fail_fun() {
		local bot_return="$LINE \n"
		bot_return+=" -->>> MODE OF USE \n"
		bot_return+="$LINE \n"
		bot_return+="/generate $(fun_trans "Host") $(fun_trans "Solicitud") $(fun_trans "Connection") \n"
		bot_return+="$(fun_trans "Ejemplo"): \n"
		bot_return+="/generate www.host.com (1 a 9) (1 a 3) \n"
		bot_return+="/generate www.host.com 2 1 \n"
		bot_return+="$LINE \n"
		bot_return+="$(fun_trans "Request Methods") \n${LINE} \n1-GET, 2-CONNECT, 3-PUT, 4-OPTIONS, 5-DELETE, 6-HEAD, 7-TRACE, 8-PROPATCH, 9-PATCH \n"
		bot_return+="$LINE \n"
		bot_return+="$(fun_trans "Connection Methods") \n${LINE} \n1-REALDATA, 2-NETDATA, 3-RAW \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		unset bot_return
		return 0
	}
	valor1="$1"        #Host input
	valor2="127.0.0.1" #IP input
	valor3="$2"        #Required Method
	valor4="$3"        #Connection Method
	[[ "$1" = "" ]] && fail_fun && return 0
	[[ "$2" = "" ]] && fail_fun && return 0
	[[ "$3" = "" ]] && fail_fun && return 0
	case $valor3 in
	1) req="GET" ;;
	2) req="CONNECT" ;;
	3) req="PUT" ;;
	4) req="OPTIONS" ;;
	5) req="DELETE" ;;
	6) req="HEAD" ;;
	7) req="PATCH" ;;
	8) req="POST" ;;
	*) req="GET" ;;
	esac
	case $valor4 in
	1) in="realData" ;;
	2) in="netData" ;;
	3) in="raw" ;;
	*) in="netData" ;;
	esac
	generate_pays Payloads.txt
	sed -i "s;realData;abc;g" $HOME/Payloads.txt
	sed -i "s;netData;abc;g" $HOME/Payloads.txt
	sed -i "s;raw;abc;g" $HOME/Payloads.txt
	sed -i "s;abc;$in;g" $HOME/Payloads.txt
	sed -i "s;GET;$req;g" $HOME/Payloads.txt
	sed -i "s;get;$req;g" $HOME/Payloads.txt
	sed -i "s;mhost;$valor1;g" $HOME/Payloads.txt
	sed -i "s;mip;$valor2;g" $HOME/Payloads.txt
	if [[ -e $HOME/Payloads.txt ]]; then
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "SUCCESSFULLY GENERATED PAYLOADS") \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		local bot_return2
		TeleBot.sendDocument --chat_id ${message_chat_id[$id]} \
		--document @$HOME/Payloads.txt
		return 0
	else
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "PAYLOADS NOT GENERATED") \n"
		bot_return+="$(fun_trans "Some Error") \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	fi
}
scan_fun() {
	error_fun() {
		local bot_return="$LINE \n"
		bot_return+=" -->>> Mode of Use \n"
		bot_return+="$LINE \n"
		bot_return+="Example: /scan www.host.com \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	}
	[[ -z $1 ]] && error_fun && return 0
	local HOST=$1
	local RETURN=$(curl -sSL "$HOST" | grep -Eoi '<a [^>]+>' | grep -Eo 'href="[^ \"]+"' | grep -Eo '(http|https)://[a-zA-Z0-9./*]+' | sort -u | uniq)
	if [[ -z $RETURN ]]; then
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "No Host Found in Domain"): ${1} \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	else
		i=1
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "SUBDOMAINS FOUND") \n$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		unset bot_return
		while read hostreturn; do
			local bot_return+="$hostreturn \n"
			if [[ $i -gt 20 ]]; then
				TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
				--text "*$(echo -e $bot_return)*" \
				--parse_mode markdown
				unset bot_return
				unset i
			fi
			let i++
		done <<<"$RETURN"
		[[ ! -z $bot_return ]] && {
			TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
			--text "*$(echo -e $bot_return)*" \
			--parse_mode markdown
		}
	fi
}

openadd_fun() {
	[[ $(dpkg --get-selections | grep -w "openvpn" | head -1) ]] || return 0
	[[ -e /etc/openvpn/openvpn-status.log ]] || return 0
	newclient "$nomeuser" "$senhauser"
	[[ -z $1 ]] && client="adm" || client="$1"
	cp /etc/openvpn/client-common.txt $HOME/$client.ovpn
	echo "<key>
 $(cat /etc/openvpn/client-key.pem)
 </key>
 <cert>
 $(cat /etc/openvpn/client-cert.pem)
 </cert>
 <ca>
 $(cat /etc/openvpn/ca.pem)
 </ca>" >>$HOME/$client.ovpn
	[[ ! -z $1 ]] && [[ ! -z $2 ]] && sed -i "s;auth-user-pass;<auth-user-pass> \n$1 \n$2 \n</auth-user-pass>;g" $HOME/$client.ovpn
	local bot_return="$LINE \n"
	bot_return+="$(fun_trans "To Generate Files With Automatic Authentication Use"): \n/openadd user senha \n$LINE \n"
	bot_return+="$(fun_trans "SUCCESSFULLY GENERATED OPENVPN FILE") \n"
	bot_return+="$LINE \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "$(echo -e $bot_return)" \
	--parse_mode markdown
	local bot_return2
	TeleBot.sendDocument --chat_id ${message_chat_id[$id]} \
	--document @$HOME/$client.ovpn
	rm $HOME/$client.ovpn
	return 0
}
cript_fun() {
	if [[ -z $2 ]]; then
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "Mode of Use"): \n"
		bot_return+="/criptar texto_for_cript \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "_$(echo -e $bot_return)_" \
		--parse_mode markdown
		return 0
	else
		local array=($@)
		for ((i = 1; i <= ${#array[@]}; i++)); do
			unset txtofus
			local number=$(expr length "${array[$i]}")
			for ((e = 1; e < $number + 1; e++)); do
				local txt[$e]=$(echo "${array[$i]}" | cut -b $e)
				case ${txt[$e]} in
				".") txt[$e]="#" ;;
				"#") txt[$e]="." ;;
				"1") txt[$e]="%" ;;
				"%") txt[$e]="1" ;;
				"2") txt[$e]="?" ;;
				"?") txt[$e]="2" ;;
				"3") txt[$e]="&" ;;
				"&") txt[$e]="3" ;;
				"/") txt[$e]="!" ;;
				"!") txt[$e]="/" ;;
				"a") txt[$e]="k" ;;
				"k") txt[$e]="a" ;;
				"s") txt[$e]="w" ;;
				"w") txt[$e]="s" ;;
				"h") txt[$e]="y" ;;
				"y") txt[$e]="h" ;;
				"o") txt[$e]="P" ;;
				"P") txt[$e]="o" ;;
				"v") txt[$e]="T" ;;
				"T") txt[$e]="v" ;;
				"f") txt[$e]="Z" ;;
				"Z") txt[$e]="f" ;;
				esac
				txtofus+="${txt[$e]}"
			done
			[[ -z $returntxt ]] && returntxt="$(echo $txtofus | rev)" || returntxt="$returntxt $(echo $txtofus | rev)"
		done
		unset txtofus
		local bot_return="$LINE \n"
		bot_return+="$(fun_trans "YOUR TEXT ENCRYPTED OR DECRYPTED"): \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "*$(echo -e $bot_return)*" \
		--parse_mode markdown
		local bot_return="$returntxt \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "_$(echo -e $bot_return)_" \
		--parse_mode markdown
	fi
}
language_fun() {
	if [[ -z $2 || -z $3 ]]; then
		local bot_return="$LINE \n"
		bot_return+=" -->>> Mode of USE \n"
		bot_return+="$LINE \n"
		bot_return+="/lang (pt, fr, es, en...) (text) \n"
		bot_return+="/lang is Hello \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "_$(echo -e $bot_return)_" \
		--parse_mode markdown
		return 0
	else
		local array=($@)
		local RETORNO
		for ((i = 2; i <= ${#array[@]}; i++)); do
			local RET=$(source trans -b :$2 "${array[$i]}")
			[[ -z $RETORNO ]] && RETORNO=$RET || RETORNO="$RETORNO $RET"
		done
		local bot_return="$LINE \n"
		bot_return+="* Your Translation: * \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "*$(echo -e $bot_return)*" \
		--parse_mode markdown
		bot_return="$(echo $RETORNO | sed -e 's/[^a-z0-9 -]//ig') \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "_$(echo -e $bot_return)_" \
		--parse_mode markdown
		return 0
	fi
}
teste_fun() {
	local bot_return="$LINE \n"
	bot_return+="$(fun_trans "USER"): ${chatuser} \n"
	bot_return+="$(fun_trans "ARGUMENTS"): ${comando[@]} \n"
	bot_return+="$LINE \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "_$(echo -e $bot_return)_" \
	--parse_mode markdown
	#local bot_return="$LINE \n"
	#          bot_return+="$(fun_trans "ESSE USUARIO"): ${chatuser} \n"
	#          bot_return+="$(fun_trans "ESSES ARGUMENTOS"): ${comando[@]} \n"
	#          bot_return+="$LINE \n"
	#          TeleBot.editMessageText --chat_id ${message_chat_id[$id]} --message_id ${reply_to_message_message_id[$id]} --text "$(echo -e $bot_return)" --parse_mode markdown
	#return 0
}

## RENEW USER

renew_user_fun() {
	#Name
	fail_fun() {
		local bot_return="*$LINE* \n"
		bot_return+=" -->>> Mode of USE \n"
		bot_return+="*$LINE* \n"
		bot_return+="/renew user days \n"
		bot_return+="Example:_ \n"
		bot_return+="/renew <user> 30 \n"
		bot_return+="*$LINE* \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		unset bot_return
		return 0
	}
	[[ "$1" = "" ]] && fail_fun && return 0
	[[ "$2" = "" ]] && fail_fun && return 0
	error_fun() {
		local bot_return="*$LINE* \n"
		bot_return+="*❗️ UNREGISTERED USER  ❗️* \n"
		bot_return+="*$LINE* \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown

		return 0
	}

	[[ -z $1 ]] && error_fun && return 0
	cup1="$1"
	userva="$(cat /etc/DXVPN/DXVPN-User | grep -w "$cup1" | cut -d'|' -f1)"

	[[ -z $userva ]] && error_fun && return 0

	datexp=$(date "+%F" -d " + $2 days") && valid=$(date '+%C%y-%m-%d' -d " + $2 days")
	chage -E $valid $1 2>/dev/null || return 1
	[[ -e ${USRdatabase} ]] && {
		newbase=$(cat ${USRdatabase} | grep -w -v "$1")
		useredit=$(cat ${USRdatabase} | grep -w "$1")
		pass=$(echo $useredit | cut -d'|' -f2)
		limit=$(echo $useredit | cut -d'|' -f4)
		echo "$1|$pass|${datexp}|$limit" >${USRdatabase}
		for value in $(echo ${newbase}); do
			echo $value >>${USRdatabase}
		done
	}

	NOM=$(less /etc/DXVPN/controller/name.log) >/dev/null 2>&1
	NOM1=$(echo $NOM) >/dev/null 2>&1
	IP="$(cat /etc/DXVPN/DXVPN-VPS)"

	local bot_return="*$LINE* \n"
	bot_return+="*ACCOUNT RENEWED*  \n"
	bot_return+="*$LINE* \n"
	bot_return+="▪️ User:_ *$1*  \n"
	bot_return+="▪️ _Added Days:_  *$2*  \n"
	bot_return+="🕰 _Now expires:_ \n👉 *$datexp*  \n"
	bot_return+="*$LINE* \n"
	bot_return+="▪️ _VPS: _ *$NOM1*  \n"
	bot_return+="▪️ _IP:_ *$IP*  \n"
	bot_return+="*$LINE* \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "$(echo -e $bot_return)" \
	--parse_mode markdown

}

#INFO SSH

info_sshp() {
	error_fun() {
		local bot_return="*$LINE* \n"
		bot_return+="*Mode of Use:* \n"
		bot_return+="*$LINE* \n"
		bot_return+="Put the Command /SSHI (ENTER USERNAME)  \n"
		bot_return+="*$LINE* \n"
		bot_return+="_Example: /SSHI DXVPN-xzcmo _ \n"
		bot_return+="*$LINE* \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	}

	[[ -z $1 ]] && error_fun && return 0

	VPSsec=$(date +%s)

	sen=$(cat /etc/DXVPN/DXVPN-User | grep -w "$1" | cut -d '|' -f2)
	[[ -z $sen ]] && sen="???"
	DateExp="$(cat /etc/DXVPN/DXVPN-User | grep -w "$1" | cut -d'|' -f3)"
	if [[ ! -z $DateExp ]]; then
		DataSec=$(date +%s --date="$DateExp")
		[[ "$VPSsec" -gt "$DataSec" ]] && EXPTIME="${red}[EXPIRED]" || EXPTIME="${gren}[$(($(($DataSec - $VPSsec)) / 86400))]"
	else
		EXPTIME="???"
	fi
	limit=$(cat /etc/DXVPN/DXVPN-User | grep -w "$1" | cut -d '|' -f4)
	[[ -z $limit ]] && limit="???"

	local bot_return="*$LINE* \n"
	bot_return+="*📝 GENERAL INFO SSH 📝* \n"
	bot_return+="*$LINE* \n"
	bot_return+="▪️ User: *$1 * \n"
	#bot_return+="$(fun_trans "Password"): $sen \n"
	bot_return+="▪️ Remaining days: *$EXPTIME * \n"
	bot_return+="▪️ User Limit: *$limit * \n"
	bot_return+="*$LINE* \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "$(echo -e $bot_return)" \
	--parse_mode markdown

	return 0
}
## PID DROPBEAR

droppids() {
	local pids
	local port_dropbear=$(ps aux | grep dropbear | awk NR==1 | awk '{print $17;}')
	cat /var/log/auth.log | grep "$(date | cut -d' ' -f2,3)" >/var/log/authday.log
	#cat /var/log/auth.log|tail -1000 > /var/log/authday.log
	local log=/var/log/authday.log
	local loginsukses='Password auth succeeded'
	[[ -z $port_dropbear ]] && return 1
	for port in $(echo $port_dropbear); do
		for pidx in $(ps ax | grep dropbear | grep "$port" | awk -F" " '{print $1}'); do
			pids="${pids}$pidx \n"
		done
	done
	for pid in $(echo -e "$pids"); do
		pidlogs=$(grep $pid $log | grep "$loginsukses" | awk -F" " '{print $3}')
		i=0
		for pidend in $pidlogs; do
			let i++
		done
		if [[ $pidend ]]; then
			login=$(grep $pid $log | grep "$pidend" | grep "$loginsukses")
			PID=$pid
			user=$(echo $login | awk -F" " '{print $10}' | sed -r "s/'//g")
			waktu=$(echo $login | awk -F" " '{print $2"-"$1,$3}')
			[[ -z $user ]] && continue
			echo "$user|$PID|$waktu"
		fi
	done
}

## B/U USER
blo_unb_fun() {
	error_fun() {
		local bot_return="*$LINE* \n"
		bot_return+="*MODE OF USE:* \n"
		bot_return+="*$LINE* \n"
		bot_return+="Give the Command /block (ENTER USERNAME)  \n"
		bot_return+=" \t---- O -----  \n"
		bot_return+="Put the Command /unblock (ENTER USERNAME)  \n"
		bot_return+="*$LINE* \n"
		bot_return+="_Example: block <name> _ \n"
		bot_return+="_Example: unblock <name> _ \n"
		bot_return+="*$LINE* \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	}

	[[ -z $1 ]] && error_fun && return 0
	local USRloked="/etc/DXVPN/DXVPN-Userlock"
	local LIMITERLOG="${USRdatabase}/Limiter.log"
	local LIMITERLOG2="${USRdatabase}/Limiter2.log"
	if [[ $2 = "-loked" ]]; then
		[[ $(cat ${USRloked} | grep -w "$1") ]] && return 1
		echo " $1 (BLOCK-MULTILOGIN) $(date +%r--%d/%m/%y)"
		limseg="$(less /etc/DXVPN/controller/todays.log)"
		KEY="2012880601:AAEJ3Kk18PGDzW57LpTMnVMn_pQYQKW3V9w"
		URL="https://api.telegram.org/bot$KEY/sendMessage"
		MSG="⚠️ VPS NOTICE: $NOM1 ⚠️
 🔹 ACCOUNT: $1 
 ❗️📵 FIXED/TEMPORARY BLOCK 📵❗️
 🔓( AUTOUNLOCK IN $limseg SECONDS) 🔓"
		curl -s --max-time 10 -d "chat_id=$IDB1&disable_web_page_preview=1&text=$MSG" $URL &>/dev/null

		pkill -u $1 &>/dev/null

	fi
	if [[ $(cat ${USRloked} | grep -w "$1") ]]; then
		usermod -U "$1" &>/dev/null
		local bot_return="*$LINE* \n"
		bot_return+="*⭕️ UNBLOCK USER ⭕️* \n"
		bot_return+="*$LINE* \n"
		bot_return+="▪️ _User:_ *$1 * _Unblocked_ \n"
		bot_return+="*$LINE* \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown

		[[ -e ${USRloked} ]] && {
			newbase=$(cat ${USRloked} | grep -w -v "$1")
			[[ -e ${USRloked} ]] && rm ${USRloked}
			for value in $(echo ${newbase}); do
				echo $value >>${USRloked}
			done
		}
		[[ -e ${LIMITERLOG} ]] && [[ $(cat ${LIMITERLOG} | grep -w "$1") ]] && {
			newbase=$(cat ${LIMITERLOG} | grep -w -v "$1")
			[[ -e ${LIMITERLOG} ]] && rm ${LIMITERLOG}
			for value in $(echo ${newbase}); do
				echo $value >>${LIMITERLOG}
				echo $value >>${LIMITERLOG}

			done

		}
		return 1
	else
		usermod -L "$1" &>/dev/null
		pkill -u $1 &>/dev/null

		droplim=$(droppids | grep -w "$1" | cut -d'|' -f2)
		kill -9 $droplim &>/dev/null

		echo $1 >>${USRloked}

		local bot_return="*$LINE* \n"
		bot_return+="*❌ BLOCK USER ❌* \n"
		bot_return+="*$LINE* \n"
		bot_return+="▪️ _User:_ *$1 * _Blocked_ \n"
		bot_return+="*$LINE* \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		#notifi &>/dev/null
		return 0
	fi

}

###READ USER BLOCK

userblock_lee() {

	local HOST="/etc/DXVPN/DXVPN-Userlock"
	local RETURN=$(cat $HOST)
	if [[ -z $RETURN ]]; then
		local bot_return="$LINE \n"
		bot_return+="NO USER BLOCKED \n"
		bot_return+="$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		return 0
	else
		i=1
		local bot_return="*$LINE* \n"
		bot_return+="* ❌ BLOCKED USERS ❌* \n$LINE \n"
		TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
		--text "$(echo -e $bot_return)" \
		--parse_mode markdown
		unset bot_return
		while read hostreturn; do
			local bot_return+="$hostreturn \n"
			if [[ $i -gt 25 ]]; then
				TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
				--text "*$(echo -e $bot_return)*" \
				--parse_mode markdown
				unset bot_return
				unset i
			fi
			let i++
		done <<<"$RETURN"
		[[ ! -z $bot_return ]] && {
			TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
			--text "*$(echo -e $bot_return)*" \
			--parse_mode markdown
		}
	fi

	local bot_return="*$LINE* \n"
	bot_return+="THESE ARE USERS WITH BAN \n"
	bot_return+="*$LINE* \n"
	TeleBot.sendMessage --chat_id ${message_chat_id[$id]} \
	--text "*$(echo -e $bot_return)*" \
	--parse_mode markdown

	return 0
}
backups() {
	[[ ! -z ${callback_query_message_chat_id[$id]} ]] && var=${callback_query_message_chat_id[$id]} || var=${message_chat_id[$id]}
	local bot_return="$LINE \n"
	bot_return+="ᨉUSER BACKUPᨉ \n"
	bot_return+="$LINE \n"
	TeleBot.sendMessage --chat_id $var \
	--text "*$(echo -e $bot_return)*" \
	--parse_mode markdown
	cp ${USRdatabase} $HOME/DXVPN-Backup-User
	TeleBot.sendDocument --chat_id $var \
	--document @$HOME/DXVPN-Backup-User

	#rm $HOME/DXVPN-Backup
	return 0
}

restabackup() {
	dirbackup="/root/DXVPN-Backup-User"
	local msj
	VPSsec=$(date +%s)
	while read line; do
		nome=$(echo ${line} | cut -d'|' -f1)
		[[ $(echo $(mostrar_usuarios) | grep -w "$nome") ]] && {
			msj="$nome [ERROR] \n"
			[[ ! -z ${callback_query_message_chat_id[$id]} ]] && var=${callback_query_message_chat_id[$id]} || var=${message_chat_id[$id]}
			TeleBot.sendMessage --chat_id $var \
			--text "*$(echo -e $msj)*" \
			--parse_mode markdown
			continue
		}

		senha=$(echo ${line} | cut -d'|' -f2)
		DateExp=$(echo ${line} | cut -d'|' -f3)
		DataSec=$(date +%s --date="$DateExp")
		[[ "$VPSsec" -lt "$DataSec" ]] && dias="$(($(($DataSec - $VPSsec)) / 86400))" || dias="NP"
		limite=$(echo ${line} | cut -d'|' -f4)

		add_user "$nome" "$senha" "$dias" "$limite" &>/dev/null && msj="$nome [VALID ACCOUNT] \n" || msj="$nome [INVALID ACCOUNT EXPIRED DATE] \n"
		[[ ! -z ${callback_query_message_chat_id[$id]} ]] && var=${callback_query_message_chat_id[$id]} || var=${message_chat_id[$id]}
		TeleBot.sendMessage --chat_id $var \
		--text "*$(echo -e $msj)*" \
		--parse_mode markdown
	done <${dirbackup}
	return 0
}

# LOOP LISTENING TO TELEGRAM
while true; do
	TeleBot.getUpdates --limit 100 --offset $(TeleBot.OffsetNext) --timeout 30
	for id in $(TeleBot.ListUpdates); do
		chatuser="$(echo ${message_chat_id[$id]} | cut -d'-' -f2)"
		echo $chatuser >&2
		comando=(${message_text[$id]})
		case ${comando[0]} in
		/[Tt]este | [Tt]este) teste_fun & ;;
		/[Aa]juda | [Aa]juda | [Hh]elp | /[Hh]elp) ajuda_fun & ;;
		/[Ss]tart | [Ss]tart | [Cc]omecar | /[Cc]omecar) ajuda_fun & ;;
		/[Ss]SHI | [Ss]SHI) info_sshp "${comando[1]}" & ;;
		/[Aa]DMIN | [Aa]DMIN) ativarid_fun "${comando[1]}" "${comando[2]}" "$chatuser" ;;
		*) if [[ ! -z $LIBERADOS ]] && [[ $(echo ${LIBERADOS} | grep -w "${chatuser}") ]]; then
			case ${comando[0]} in

			##PANEL SSH

			[Oo]nline | /[Oo]nline | [Oo]nlines | /[Oo]nlines) online_fun & ;;
			[Cc]riptar | /[Cc]riptar | [Cc]ript | /[Cc]ript) cript_fun "${comando[@]}" & ;;
			[Aa]gregar | /[Aa]gregar) useradd_fun "${comando[1]}" "${comando[2]}" "${comando[3]}" "${comando[4]}" & ;;
			[Ee]liminar | /[Ee]liminar) userdell_fun "${comando[1]}" & ;;
			[Rr]enovar | /[Rr]enovar) renew_user_fun "${comando[1]}" "${comando[2]}" & ;;
			[Bb]loquear | /[Bb]loquear) blo_unb_fun "${comando[1]}" & ;;
			[Dd]esbloquear | /[Dd]esbloquear) blo_unb_fun "${comando[1]}" & ;;
			[Vv]erbloqueados | /[Vv]erbloqueados) userblock_lee & ;;
			
            ##TOOLS

			[Aa]dmins | /[Aa]dmins) loguin_fun & ;;
			[Ii]nfovps | /[Ii]nfovps) infovps & ;;
			[Bb]ackup | /[Bb]ackup) backups & ;;
			[Rr]estarbackup | /[Rr]estarbackup) restabackup & ;;
			[Ll]ang | /[Ll]ang) language_fun "${comando[@]}" & ;;
			[Oo]penadd | /[Oo]penadd | [Oo]pen | /[Oo]pen) openadd_fun "${comando[1]}" "${comando[2]}" & ;;
			[Gg]erar | /[Gg]erar | [Pp]ay | /[Pp]ay) paygen_fun "${comando[1]}" "${comando[2]}" "${comando[3]}" & ;;
			[Uu]suarios | /[Uu]suarios | [Uu]ser | /[Uu]ser) info_fun & ;;
			[Ss]can | /[Ss]can) scan_fun "${comando[1]}" & ;;

			*) ajuda_fun ;;

			esac
		else
			[[ ! -z "${comando[0]}" ]] && blockfun &
		fi ;;
		esac
	done
done