#!/usr/bin/env bash

#------------------------------------------------ -------------------------------------------------- --------
# DATE: 05 July 2023
# SCRIPT: telebot.sh
# VERSION: 1.0.0
# DEVELOPED BY: DXVPN
# TELEGRAM : https://t.me/dkrimxplus
# GITHUB: https://github.com/thoiruddin/dxvpn
#
# DESCRIPTION: Telebot is an unofficial API developed to facilitate the creation of
# bots on the TELEGRAM platform. Consisting of a collection of methods
# and functions that allow the developer to:
#
# * Manage groups, channels and members.
# * Send messages, documents, music, contacts and etc.
# * Send keyboards (KeyboardMarkup and InlineKeyboard).
# * Get information about members, files, groups and channels.
# * For more information see the documentation:
#
#-----------------------------------------------------------------------------------------------------------

[[ $_TELEBOT_SH_ ]] && return 1

#if ! awk 'BEGIN { exit DXVPN[1] < 4.3 }' ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}; then
#	echo "${BASH_SOURCE:-${0##*/}}: error: requires shell 'bash 4.3' or higher." 1>&2
#	exit 1
#fi

# Information
readonly -A _TELEBOT_=(
[name]='Telebot'
[keywords]='Telebot Script Telegram API'
[description]='Unofficial API for creating bots on the Telegram platform.'
[version]='1.0.0'
[language]='shellscript'
[tele]=${TELE}
[tele_version]=${BASH_VERSION}
[author]='DXVPN'
[email]='dkrimx@gmail.com'
[github]='https://github.com/thoiruddin/dxvpn'
[packages]='curl 7.0, getopt 2.0, jq 1.5'
)

# Check dependencies.
while read _pkg_ _ver_; do
	if command -v $_pkg_ &>/dev/null; then
		if [[ $($_pkg_ --version 2>&1) =~ [0-9]+\.[0-9]+ ]]; then
			if ! awk 'BEGIN { exit DXVPN[1] < DXVPN[2] }' $BASH_REMATCH $_ver_; then
				printf "%s: error: requires package '%s %s' or higher.\n" ${_TELEBOT_[name]} $_pkg_ $_ver_ 1>&2
				exit 1
			fi
		else
			printf "%s: error: '%s' could not get version.\n" ${_TELEBOT_[name]} $_pkg_ 1>&2
			exit 1
		fi
	else
		printf "%s: error: '%s' required package is missing.\n" ${_TELEBOT_[name]} $_pkg_ 1>&2
		exit 1
	fi
done <<< "${_TELEBOT_[packages]//,/$'\n'}"

# bash (options).
shopt -s	checkwinsize			\
			cmdhist					\
			complete_fullquote		\
			expand_aliases			\
			extglob					\
			extquote				\
			force_fignore			\
			histappend				\
			interactive_comments	\
			progcomp				\
			promptvars				\
			sourcepath

# Disable file name expansion
set -f

readonly _TELEBOT_SH_=1						# Initialization
readonly _BOT_SCRIPT_=${0##*/}				# Script
readonly _CURL_OPT_='--silent --request'	# CURL (options)

# Errors
readonly _ERR_TYPE_BOOL_='type mismatch: support only "true" or "false".'
readonly _ERR_TYPE_INT_='Type mismatch: supports integer only.'
readonly _ERR_TYPE_FLOAT_='Type mismatch: supports float only.'
readonly _ERR_PARAM_REQUIRED_='required option: check if required parameter(s) or argument(s) are present.'
readonly _ERR_TOKEN_UNAUTHORIZED_='unauthorized: check if you have permissions to use the token.'
readonly _ERR_TOKEN_INVALID_='invalid token: check the token number and try again.'
readonly _ERR_BOT_ALREADY_INIT_='action not allowed: the bot has already been initialized.'
readonly _ERR_FILE_NOT_FOUND_='failed to access: it was not possible to read the file.'
readonly _ERR_DIR_WRITE_DENIED_='permission denied: it is not possible to write to the directory.'
readonly _ERR_DIR_NOT_FOUND_='Unable to access: directory not found.'
readonly _ERR_FILE_INVALID_ID_='invalid id: file not found.'
readonly _ERR_UNKNOWN_='unknown error: An unexpected failure occurred. Report the problem to the developer.'
readonly _ERR_SERVICE_NOT_ROOT_='Access denied: requires root privileges.'
readonly _ERR_SERVICE_EXISTS_='error creating service: service name already exists.'
readonly _ERR_SERVICE_SYSTEMD_NOT_FOUND_='error activating: the system does not support "systemd" service management.'
readonly _ERR_SERVICE_USER_NOT_FOUND_='user not found: the user account entered is invalid.'
readonly _ERR_VAR_NAME_='variable not found: identifier is invalid or does not exist.'
readonly _ERR_FUNCTION_NOT_FOUND_='Function not found: the specified identifier is invalid or does not exist.'
readonly _ERR_ARG_='invalid argument: the argument is not supported by the specified parameter.'
readonly _ERR_RULE_ALREADY_EXISTS_='failed to set: rule name already exists.'
readonly _ERR_HANDLE_EXISTS_='error when registering: there is already a handle linked to the callback'
readonly _ERR_CONNECTION_='connection failure: it was not possible to establish a connection with Telegram.'

# Maps
declare -A _BOT_HANDLE_
declare -A _BOT_RULES_
declare -A return

declare -i _BOT_RULES_INDEX_
declare _VAR_INIT_

Json() { local obj=$(jq -Mc "$1" <<< "${*:2}"); obj=${obj#\"}; echo "${obj%\"}"; }

SetDelmValues(){ 
	local obj=$(jq "[..|select(type == \"string\" or type == \"number\" or type == \"boolean\")|tostring]|join(\"${_BOT_DELM_/\"/\\\"}\")" <<< "$1")
	obj=${obj#\"}; echo "${obj%\"}"
}

GetAllValues(){
	jq '[..|select(type == "string" or type == "number" or type == "boolean")|tostring]|.[]' <<< "$1"
}

GetAllKeys(){
	jq -r 'path(..|select(type == "string" or type == "number" or type == "boolean"))|map(if type == "number" then .|tostring|"["+.+"]" else . end)|join(".")|gsub("\\.\\[";"[")' <<< "$1"
}

FlagConv()
{
	local var str=$2

	while [[ $str =~ \$\{([a-z_]+)\} ]]; do
		if [[ ${BASH_REMATCH[1]} == @(${_VAR_INIT_// /|}) ]]; then
			var=${BASH_REMATCH[1]}[$1]
			str=${str//${BASH_REMATCH[0]}/${!var}}
		else
			str=${str//${BASH_REMATCH[0]}}
		fi
	done

	echo "$str"
}

CreateLog()
{
	local fid fbot fname fuser lcode cid ctype 
	local ctitle mid mdate mtext etype
	local i fmt obj oid

	for ((i=0; i < $1; i++)); do
		
		printf -v fmt "$_BOT_LOG_FORMAT_" || MessageError API
		
		# Suppress errors.
		exec 5<&2
		exec 2<&-

		# object (type)
		if 		[[ ${message_contact_phone_number[$i]:-${edited_message_contact_phone_number[$i]}}					]] ||
				[[ ${channel_post_contact_phone_number[$i]:-${edited_channel_post_contact_phone_number[$i]}}		]]; then obj=contact
		elif	[[ ${message_sticker_file_id[$i]:-${edited_message_sticker_file_id[$i]}}							]] ||
				[[ ${channel_post_sticker_file_id[$i]:-${edited_channel_post_sticker_file_id[$i]}}					]]; then obj=sticker
		elif	[[ ${message_animation_file_id[$i]:-${edited_message_animation_file_id[$i]}}						]] ||
				[[ ${channel_post_animation_file_id[$i]:-${edited_channel_post_animation_file_id[$i]}}				]]; then obj=animation
		elif	[[ ${message_photo_file_id[$i]:-${edited_message_photo_file_id[$i]}}								]] ||
				[[ ${channel_post_photo_file_id[$i]:-${edited_channel_post_photo_file_id[$i]}}						]]; then obj=photo
		elif	[[ ${message_audio_file_id[$i]:-${edited_message_audio_file_id[$i]}}								]] ||
				[[ ${channel_post_audio_file_id[$i]:-${edited_channel_post_audio_file_id[$i]}}						]]; then obj=audio
		elif	[[ ${message_video_file_id[$i]:-${edited_message_video_file_id[$i]}}								]] ||
				[[ ${channel_post_video_file_id[$i]:-${edited_channel_post_video_file_id[$i]}}						]]; then obj=video
		elif	[[ ${message_voice_file_id[$i]:-${edited_message_voice_file_id[$i]}}								]] ||
				[[ ${channel_post_voice_file_id[$i]:-${edited_channel_post_voice_file_id[$i]}}						]]; then obj=voice
		elif	[[ ${message_document_file_id[$i]:-${edited_message_document_file_id[$i]}}							]] ||
				[[ ${channel_post_document_file_id[$i]:-${edited_channel_post_document_file_id[$i]}}				]]; then obj=document
		elif	[[ ${message_venue_location_latitude[$i]:-${edited_message_venue_location_latitude[$i]}}			]] ||
				[[ ${channel_post_venue_location_latitude[$i]-${edited_channel_post_venue_location_latitude[$i]}}	]]; then obj=venue
		elif	[[ ${message_location_latitude[$i]:-${edited_message_location_latitude[$i]}}						]] ||
				[[ ${channel_post_location_latitude[$i]:-${edited_channel_post_location_latitude[$i]}}				]]; then obj=location
		elif	[[ ${message_text[$i]:-${edited_message_text[$i]}}													]] ||
				[[ ${channel_post_text[$i]:-${edited_channel_post_text[$i]}}										]]; then obj=text
		elif 	[[ ${callback_query_id[$i]}																			]]; then obj=callback
		elif 	[[ ${inline_query_id[$i]}																			]]; then obj=inline
		elif	[[ ${chosen_inline_result_result_id[$i]}															]]; then obj=chosen
		fi
	
		# object (id)	
		[[ ${oid:=${message_contact_phone_number[$i]}} 				]] ||
		[[ ${oid:=${message_sticker_file_id[$i]}}					]] ||
		[[ ${oid:=${message_animation_file_id[$i]}}					]] ||
		[[ ${oid:=${message_photo_file_id[$i]}}						]] ||
		[[ ${oid:=${message_audio_file_id[$i]}}						]] ||
		[[ ${oid:=${message_video_file_id[$i]}}						]] ||
		[[ ${oid:=${message_voice_file_id[$i]}}						]] ||
		[[ ${oid:=${message_document_file_id[$i]}}					]] ||
		[[ ${oid:=${edited_message_contact_phone_number[$i]}} 		]] ||
		[[ ${oid:=${edited_message_sticker_file_id[$i]}}			]] ||
		[[ ${oid:=${edited_message_animation_file_id[$i]}}			]] ||
		[[ ${oid:=${edited_message_photo_file_id[$i]}}				]] ||
		[[ ${oid:=${edited_message_audio_file_id[$i]}}				]] ||
		[[ ${oid:=${edited_message_video_file_id[$i]}}				]] ||
		[[ ${oid:=${edited_message_voice_file_id[$i]}}				]] ||
		[[ ${oid:=${edited_message_document_file_id[$i]}}			]] ||
		[[ ${oid:=${channel_post_contact_phone_number[$i]}} 		]] ||
		[[ ${oid:=${channel_post_sticker_file_id[$i]}}				]] ||
		[[ ${oid:=${channel_post_animation_file_id[$i]}}			]] ||
		[[ ${oid:=${channel_post_photo_file_id[$i]}}				]] ||
		[[ ${oid:=${channel_post_audio_file_id[$i]}}				]] ||
		[[ ${oid:=${channel_post_video_file_id[$i]}}				]] ||
		[[ ${oid:=${channel_post_voice_file_id[$i]}}				]] ||
		[[ ${oid:=${channel_post_document_file_id[$i]}}				]] ||
		[[ ${oid:=${edited_channel_post_contact_phone_number[$i]}} 	]] ||
		[[ ${oid:=${edited_channel_post_sticker_file_id[$i]}}		]] ||
		[[ ${oid:=${edited_channel_post_animation_file_id[$i]}}		]] ||
		[[ ${oid:=${edited_channel_post_photo_file_id[$i]}}			]] ||
		[[ ${oid:=${edited_channel_post_audio_file_id[$i]}}			]] ||
		[[ ${oid:=${edited_channel_post_video_file_id[$i]}}			]] ||
		[[ ${oid:=${edited_channel_post_voice_file_id[$i]}}			]] ||
		[[ ${oid:=${edited_channel_post_document_file_id[$i]}}		]] ||
		[[ ${oid:=${message_message_id[$i]}}						]] ||
		[[ ${oid:=${edited_message_message_id[$i]}}					]] ||
		[[ ${oid:=${channel_post_message_id[$i]}}					]] ||
		[[ ${oid:=${edited_channel_post_message_id[$i]}}			]] ||
		[[ ${oid:=${callback_query_id[$i]}}							]] ||
		[[ ${oid:=${inline_query_id[$i]}} 							]] ||
		[[ ${oid:=${chosen_inline_result_result_id[$i]}}			]]

		# Sender (id)
		[[ ${fid:=${message_from_id[$i]}}				]] ||
		[[ ${fid:=${edited_message_from_id[$i]}} 		]] ||
		[[ ${fid:=${callback_query_from_id[$i]}} 		]] ||
		[[ ${fid:=${inline_query_from_id[$i]}} 			]] ||
		[[ ${fid:=${chosen_inline_result_from_id[$i]}} 	]]

		# Bot
		[[ ${fbot:=${message_from_is_bot[$i]}} 				]] ||
		[[ ${fbot:=${edited_message_from_is_bot[$i]}} 		]] ||
		[[ ${fbot:=${callback_query_from_is_bot[$i]}} 		]] ||
		[[ ${fbot:=${inline_query_from_is_bot[$i]}} 		]] ||
		[[ ${fbot:=${chosen_inline_result_from_is_bot[$i]}} ]]

		# User (name)
		[[ ${fname:=${message_from_first_name[$i]}} 				]] ||
		[[ ${fname:=${edited_message_from_first_name[$i]}}			]] ||
		[[ ${fname:=${callback_query_from_first_name[$i]}} 			]] ||
		[[ ${fname:=${inline_query_from_first_name[$i]}}			]] ||
		[[ ${fname:=${chosen_inline_result_from_first_name[$i]}}	]] ||
		[[ ${fname:=${channel_post_author_signature[$i]}}			]] ||
		[[ ${fname:=${edited_channel_post_author_signature[$i]}}	]]

		# User (account)
		[[ ${fuser:=${message_from_username[$i]}}				]] ||
		[[ ${fuser:=${edited_message_from_username[$i]}} 		]] ||
		[[ ${fuser:=${callback_query_from_username[$i]}} 		]] ||
		[[ ${fuser:=${inline_query_from_username[$i]}} 			]] ||
		[[ ${fuser:=${chosen_inline_result_from_username[$i]}} 	]]

		# language
		[[ ${lcode:=${message_from_language_code[$i]}} 				]] ||
		[[ ${lcode:=${edited_message_from_language_code[$i]}} 		]] ||
		[[ ${lcode:=${callback_query_from_language_code[$i]}} 		]] ||
		[[ ${lcode:=${inline_query_from_language_code[$i]}} 		]] ||
		[[ ${lcode:=${chosen_inline_result_from_language_code[$i]}}	]]

		# Chat (id)
		[[ ${cid:=${message_chat_id[$i]}}					]] ||
		[[ ${cid:=${edited_message_chat_id[$i]}}			]] ||
		[[ ${cid:=${callback_query_message_chat_id[$i]}} 	]] ||
		[[ ${cid:=${channel_post_chat_id[$i]}}				]] ||
		[[ ${cid:=${edited_channel_post_chat_id[$i]}}		]]

		# Chat (type)
		[[ ${ctype:=${message_chat_type[$i]}} 					]] ||
		[[ ${ctype:=${edited_message_chat_type[$i]}} 			]] ||
		[[ ${ctype:=${callback_query_message_chat_type[$i]}} 	]] ||
		[[ ${ctype:=${channel_post_chat_type[$i]}}				]] ||
		[[ ${ctype:=${edited_channel_post_chat_type[$i]}}		]]

		# Chat (Title)
		[[ ${ctitle:=${message_chat_title[$i]}}					]] ||
		[[ ${ctitle:=${edited_message_chat_title[$i]}} 			]] ||
		[[ ${ctitle:=${callback_query_message_chat_title[$i]}} 	]] ||
		[[ ${ctitle:=${channel_post_chat_title[$i]}}			]] ||
		[[ ${ctitle:=${edited_channel_post_chat_title[$i]}}		]]

		# Message (id)
		[[ ${mid:=${message_message_id[$i]}} 				]] ||
		[[ ${mid:=${edited_message_message_id[$i]}} 		]] ||
		[[ ${mid:=${callback_query_id[$i]}} 				]] ||
		[[ ${mid:=${inline_query_id[$i]}} 					]] ||
		[[ ${mid:=${chosen_inline_result_result_id[$i]}}	]] ||
		[[ ${mid:=${channel_post_message_id[$i]}}			]] ||
		[[ ${mid:=${edited_channel_post_message_id[$i]}}	]]

		# Message (date)
		[[ ${mdate:=${message_date[$i]}}				]] ||
		[[ ${mdate:=${edited_message_date[$i]}} 		]] ||
		[[ ${mdate:=${callback_query_message_date[$i]}}	]] ||
		[[ ${mdate:=${channel_post_date[$i]}}			]] ||
		[[ ${mdate:=${edited_channel_post_date[$i]}}	]]

		# Message (text)
		[[ ${mtext:=${message_text[$i]}} 				]] ||
		[[ ${mtext:=${edited_message_text[$i]}} 		]] ||
		[[ ${mtext:=${callback_query_message_text[$i]}} ]] ||
		[[ ${mtext:=${inline_query_query[$i]}} 			]] ||
		[[ ${mtext:=${chosen_inline_result_query[$i]}}	]] ||
		[[ ${mtext:=${channel_post_text[$i]}}			]] ||
		[[ ${mtext:=${edited_channel_post_text[$i]}}	]]

		# Message (type)
		[[ ${etype:=${message_entities_type[$i]}} 					]] ||
		[[ ${etype:=${edited_message_entities_type[$i]}} 			]] ||
		[[ ${etype:=${callback_query_message_entities_type[$i]}}	]] ||
		[[ ${etype:=${channel_post_entities_type[$i]}}				]] ||
		[[ ${etype:=${edited_channel_post_entities_type[$i]}}		]]

		# Flags
		fmt=${fmt//\{BOT_TOKEN\}/${_BOT_INFO_[0]:--}}
		fmt=${fmt//\{BOT_ID\}/${_BOT_INFO_[1]:--}}
		fmt=${fmt//\{BOT_FIRST_NAME\}/${_BOT_INFO_[2]:--}}
		fmt=${fmt//\{BOT_USERNAME\}/${_BOT_INFO_[3]:--}}
		fmt=${fmt//\{BASENAME\}/${_BOT_SCRIPT_:--}}
		fmt=${fmt//\{OK\}/${return[ok]:-${ok:--}}}
		fmt=${fmt//\{UPDATE_ID\}/${update_id[$i]:--}}
		fmt=${fmt//\{OBJECT_TYPE\}/${obj:--}}
		fmt=${fmt//\{OBJECT_ID\}/${oid:--}}
		fmt=${fmt//\{FROM_ID\}/${fid:--}}
		fmt=${fmt//\{FROM_IS_BOT\}/${fbot:--}}
		fmt=${fmt//\{FROM_FIRST_NAME\}/${fname:--}}
		fmt=${fmt//\{FROM_USERNAME\}/${fuser:--}}
		fmt=${fmt//\{FROM_LANGUAGE_CODE\}/${lcode:--}}
		fmt=${fmt//\{CHAT_ID\}/${cid:--}}
		fmt=${fmt//\{CHAT_TYPE\}/${ctype:--}}
		fmt=${fmt//\{CHAT_TITLE\}/${ctitle:--}}
		fmt=${fmt//\{MESSAGE_ID\}/${mid:--}}
		fmt=${fmt//\{MESSAGE_DATE\}/${mdate:--}}
		fmt=${fmt//\{MESSAGE_TEXT\}/${mtext:--}}
		fmt=${fmt//\{ENTITIES_TYPE\}/${etype:--}}
		fmt=${fmt//\{METHOD\}/${FUNCNAME[2]/main/TeleBot.getUpdates}}
		fmt=${fmt//\{RETURN\}/$(SetDelmValues "$2")}

		exec 2<&5

		# log
		[[ $fmt ]] && { echo "$fmt" >> "$_BOT_LOG_FILE_" || MessageError API; }

		# Clean objects
		fid= fbot= fname= fuser= lcode= cid= ctype= 
		ctitle= mid= mdate= mtext= etype= obj= oid=
	done

	return $?
}

MethodReturn()
{
	# Return
	case $_BOT_TYPE_RETURN_ in
		json) echo "$1";;
		value) SetDelmValues "$1";;
		map)
			local key val vars vals i obj
			return=()

			mapfile -t vars <<< $(GetAllKeys "$1")
			mapfile -t vals <<< $(GetAllValues "$1")

			for i in ${!vars[@]}; do
				key=${vars[$i]//[0-9\[\]]/}
				key=${key#result.}
				key=${key//./_}

				val=${vals[$i]}
				val=${val#\"}
				val=${val%\"}
				
				[[ ${return[$key]} ]] && return[$key]+=${_BOT_DELM_}${val} || return[$key]=$val
				[[ $_BOT_MONITOR_ ]] && printf "[%s]: return[%s] = '%s'\n" "${FUNCNAME[1]}" "$key" "$val"
			done
			;;
	esac
	
	[[ $(jq -r '.ok' <<< "$1") == true ]]

	return $?
}

MessageError()
{
	# Local variables
	local err_message err_param assert i
	
	# The variable 'BASH_LINENO' is dynamic and stores the number of the line where it was expanded.
	# When called inside a subshell, it starts to be instantiated as an array, storing several
	# values where each index refers to a shell/subshell. The same characteristics apply to the variable
	# 'FUNCNAME', where the name of the function where it was called is stored.

	# Get the index of the function in the calling hierarchy.
	[[ ${FUNCNAME[1]} == CheckArgType ]] && i=2 || i=1
	
	# Read the occurrence type.
	# TG - External error returned by telegram core.
	# API - Internal error generated by Telebot API.
	case $1 in
		TG)
			err_param="$(Json '.error_code' "$2")"
			err_message="$(Json '.description' "$2")"
			;;
		API)
			err_param="${3:--}: ${4:--}"
			err_message="$2"
			assert=true
			;;
	esac

	# Print error
	printf "%s: error: line %s: %s: %s: %s\n"					\
							"${_BOT_SCRIPT_}"					\
							"${BASH_LINENO[$i]:--}" 			\
							"${FUNCNAME[$i]:--}" 				\
							"${err_param:--}" 					\
							"${err_message:-$_ERR_UNKNOWN_}" 	1>&2 

	# End script/thread in case of internal error, otherwise return 1
	${assert:-false} && exit 1 || return 1
}

CheckArgType()
{
	# CheckArgType receives data from the calling function and verifies
	# the received data with the type supported by the parameter.
	# '0' is returned for success, otherwise a message
	# of error is returned and the script/thread is terminated with status '1'.
	case $1 in
		user)		id "$3" &>/dev/null						|| MessageError API "$_ERR_SERVICE_USER_NOT_FOUND_" "$2" "$3";;
		func)		[[ $(type -t "$3") == function			]] 	|| MessageError API "$_ERR_FUNCTION_NOT_FOUND_" "$2" "$3";;
		var)		[[ -v $3 								]] 	|| MessageError API "$_ERR_VAR_NAME_" "$2" "$3";;
		int)		[[ $3 =~ ^-?[0-9]+$ 					]] 	|| MessageError API "$_ERR_TYPE_INT_" "$2" "$3";;
		float)		[[ $3 =~ ^-?[0-9]+\.[0-9]+$ 			]] 	|| MessageError API "$_ERR_TYPE_FLOAT_" "$2" "$3";;
		bool)		[[ $3 =~ ^(true|false)$ 				]] 	|| MessageError API "$_ERR_TYPE_BOOL_" "$2" "$3";;
		token)		[[ $3 =~ ^[0-9]+:[a-zA-Z0-9_-]+$		]] 	|| MessageError API "$_ERR_TOKEN_INVALID_" "$2" "$3";;
		file)		[[ $3 =~ ^@ && ! -f ${3#@} 				]] 	&& MessageError API "$_ERR_FILE_NOT_FOUND_" "$2" "$3";;
		return)		[[ $3 == @(json|map|value) 				]] 	|| MessageError API "$_ERR_ARG_" "$2" "$3";;
		cmd)		[[ $3 =~ ^/[a-zA-Z0-9_]+$ 				]] 	|| MessageError API "$_ERR_ARG_" "$2" "$3";;
		flag)		[[ $3 =~ ^[a-zA-Z0-9_]+$ 				]] 	|| MessageError API "$_ERR_ARG_" "$2" "$3";;
	esac

	return $?
}

FlushOffset()
{    
	local sid eid jq_obj

	while :; do
		jq_obj=$(TeleBot.getUpdates --limit 100 --offset $(TeleBot.OffsetNext))
		IFS=' ' read -a update_id <<< $(jq -r '.result|.[]|.update_id' <<< $jq_obj)
		[[ $update_id ]] || break
		sid=${sid:-${update_id[0]}}
		eid=${update_id[-1]}
	done
	
	echo "${sid:-0}|${eid:-0}"

	return $?
}

CreateUnitService()
{
	local service=${1%.*}.service
	local ok='\033[0;32m[OK]\033[0;m'
	local fail='\033[0;31m[FAILURE]\033[0;m'
	
	((UID == 0)) || MessageError API "$_ERR_SERVICE_NOT_ROOT_"

	# 'service' mode requires process management system 'systemd'
	# is present for the Unit target to be linked to the service.
	if ! which systemctl &>/dev/null; then
		MessageError API "$_ERR_SERVICE_SYSTEMD_NOT_FOUND_"; fi


	# If the service exists.
	test -e /lib/systemd/system/$service && \
	MessageError API "$_ERR_SERVICE_EXISTS_" "$service"

	# Generating the target settings.
	cat > /lib/systemd/system/$service << _eof
[Unit]
Description=$1 - (TELEBOT)
After=network-online.target

[Service]
User=$2
WorkingDirectory=$PWD
ExecStart=/bin/bash $1
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/bin/kill -KILL \$MAINPID
KillMode=process
Restart=on-failure
RestartPreventExitStatus=255
Type=simple

[Install]
WantedBy=multi-user.target
_eof

	[[ $? -eq 0 ]] && {	
		
		printf '%s was successfully created !!\n' $service	
		echo -n "Enabling..."
 		systemctl enable $service &>/dev/null && echo -e $ok || \
		{ echo -e $fail; MessageError API; }

		sed -i -r '/^\s*TeleBot.init\s/s/\s--?(s(ervice)?|u(ser)?\s+\w+)\b//g' "$1"
		systemctl daemon-reload

		echo -n "Starting..."
		systemctl start $service &>/dev/null && {
		
			echo -e $ok
			systemctl status $service
			echo -e "\nUse: sudo systemctl {start|stop|restart|reload|status} $service"
		
		} || echo -e $fail
	
	} || MessageError API

	exit 0
}

# Initialize the bot, defining its API and _TOKEN_.
TeleBot.init()
{
	local method_return delm ret logfmt jq_obj offset
	local token monitor flush service user logfile logfmt
	
	# Check if the bot has already started.
	[[ $_TELEBOT_INIT_ ]] && MessageError API "$_ERR_BOT_ALREADY_INIT_"

	local param=$(getopt --name "$FUNCNAME" \
						 --options 't:mfsu:l:o:r:d:' \
						 --longoptions 'token:,
										monitor,
										flush,
										service,
										user:,
										log_file:,
										log_format:,
										return:,
										delimiter:' \
    					 -- "$@")
    
	# Define the positional parameters
	eval set -- "$param"
	
	while :
    	do
			case $1 in
				-t|--token)
	    			CheckArgType token "$1" "$2"
					token=$2
	    			shift 2
	   				;;
	   			-m|--monitor)
					# Enable monitor mode
					monitor=true
	   				shift
	   				;;
				-f|--flush)
					# Define the flush FLAG for the 'TeleBot.getUpdates' method. If enabled, it makes
					# the method get only the available updates, skipping the extraction of the
					# JSON objects and variable initialization
					flush=true
					shift
					;;
				-s|--service)
					service=true
					shift
					;;
				-u|--user)
					CheckArgType user "$1" "$2"
					user=$2
					shift 2
					;;
				-l|--log_file)
					logfile=$2
					shift 2
					;;
				-o|--log_format)
					logfmt=$2
					shift 2
					;;
				-r|--return)
					CheckArgType return "$1" "$2"
					ret=$2
					shift 2
					;;
				-d|--delimiter)
					delm=$2
					shift 2
					;;
	   			--)
	   				shift
	   				break
	   				;;
	   		esac
	   	done
  
	# Required parameter.
	[[ $token 					]]	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --token]"
	[[ $user && ! $service 		]] 	&& MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --service]" 
	[[ $service 				]]	&& CreateUnitService "$_BOT_SCRIPT_" "${user:-$USER}"
		   
	declare -gr _TOKEN_=$token											# TOKEN
	declare -gr _API_TELEGRAM_="https://api.telegram.org/bot$_TOKEN_"	# API

	# Test connection.
	curl -s "$_API_TELEGRAM_" &>- || MessageError API "$_ERR_CONNECTION_"

    # A simple method to test your bot's authentication token.
    # Does not require parameters. Returns basic information about the bot in the form of a User object.
    TeleBot.getMe()
    {
    	# Call the getMe method passing the API address, followed by the method name.
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.})

		# Check method return status
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
    }

	TeleBot.getMe &>- || MessageError API "$_ERR_TOKEN_UNAUTHORIZED_" '[-t, --token]'
	
	# Save the bot information.
	declare -gr _BOT_INFO_=(
		[0]=$_TOKEN_
		[1]=$(Json '.result.id' $jq_obj)
		[2]=$(Json '.result.first_name' $jq_obj)
		[3]=$(Json '.result.username' $jq_obj)
	)

	# Configuration.
	declare -gr _BOT_FLUSH_=$flush
	declare -gr _BOT_MONITOR_=$monitor
	declare -gr _BOT_SERVICE_=$service
	declare -gr _BOT_USER_SERVICE_=$user
	declare -gr _BOT_TYPE_RETURN_=${ret:-value}
	declare -gr _BOT_DELM_=${delm:-|}
	declare -gr _BOT_LOG_FILE_=${logfile}
	declare -gr _BOT_LOG_FORMAT_=${logfmt:-%(%d/%m/%Y %H:%M:%S)T: \{BASENAME\}: \{BOT_USERNAME\}: \{UPDATE_ID\}: \{METHOD\}: \{CHAT_TYPE\}: \{FROM_USERNAME\}: \{OBJECT_TYPE\}: \{OBJECT_ID\}: \{MESSAGE_TEXT\}}
	declare -gr _TELEBOT_INIT_=1

    # TELEBOT (FUNCTIONS)
	# Initialize functions for calls to telegram API methods.
	TeleBot.ListUpdates(){ echo ${!update_id[@]}; }
	TeleBot.TotalUpdates(){ echo ${#update_id[@]}; }
	TeleBot.OffsetEnd(){ local -i offset=${update_id[@]: -1}; echo $offset; }
	TeleBot.OffsetNext(){ echo $((${update_id[@]: -1}+1)); }
   	
	TeleBot.token() { echo "${_BOT_INFO_[0]}"; }
	TeleBot.id() { echo "${_BOT_INFO_[1]}"; }
	TeleBot.first_name() { echo "${_BOT_INFO_[2]}"; }
	TeleBot.username() { echo "${_BOT_INFO_[3]}"; }
  
	TeleBot.getConfig()
	{
		local jq_obj

		printf -v jq_obj '{"monitor":%s,"flush":%s,"service":%s,"return":"%s","delimiter":"%s","user":"%s","log_file":"%s","log_format":"%s"}'	\
							"${_BOT_MONITOR_:-false}"   \
							"${_BOT_FLUSH_:-false}"  	\
							"${_BOT_SERVICE_:-false}"   \
							"${_BOT_TYPE_RETURN_}"      \
							"${_BOT_DELM_}"				\
							"${_BOT_USER_SERVICE_}"     \
							"${_BOT_LOG_FILE_}"         \
							"${_BOT_LOG_FORMAT_}"

		MethodReturn "$jq_obj"

		return $?	
	}

    TeleBot.regHandleFunction()
    {
    	local function data handle args
    
		local param=$(getopt	--name "$FUNCNAME" \
								--options 'f:a:d:' \
								--longoptions	'function:,
												args:,
												callback_data:' \
								-- "$@")
    
		eval set -- "$param"
    		
		while :
		do
   			case $1 in
   				-f|--function)
					CheckArgType func "$1" "$2"
   					function=$2
   					shift 2
   					;;
    			-a|--args)
   					args=$2
   					shift 2
   					;;
   				-d|--callback_data)
   					data=$2
   					shift 2
   					;;
   				--)
   					shift
   					break
   					;;
   			esac
   		done

		[[ $function ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-f, --function]"
   		[[ $data ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-d, --callback_data]"

   		[[ ${_BOT_HANDLE_[$data]} ]] && MessageError API "$_ERR_HANDLE_EXISTS_" '[-d, --callback_data]'

   		_BOT_HANDLE_[$data]=func:$function' '$args

   		return 0
    }
    
	TeleBot.regHandleExec()
    {
    	local cmd data
    
		local param=$(getopt	--name "$FUNCNAME" \
								--options 'c:d:' \
								--longoptions	'command:,
												callback_data:' \
								-- "$@")
    
		eval set -- "$param"
    		
		while :
		do
   			case $1 in
   				-c|--command)
   					cmd=$2
   					shift 2
   					;;
   				-d|--callback_data)
   					data=$2
   					shift 2
   					;;
   				--)
   					shift
   					break
   					;;
   			esac
   		done

		[[ $cmd ]]	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --command]"
   		[[ $data ]]	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-d, --callback_data]"

   		[[ ${_BOT_HANDLE_[$data]} ]] && MessageError API "$_ERR_HANDLE_EXISTS_" "[-d, --callback_data]"

   		_BOT_HANDLE_[$data]=exec:$cmd

   		return 0
    }
    
    TeleBot.watchHandle()
    {
    	local data flag cmd

		local param=$(getopt --name "$FUNCNAME" \
							--options 'd' \
							--longoptions 'callback_data' \
							-- "$@")
    
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-d|--callback_data)
    				shift 2
    				data=$1
    				;;
    			*)
    				shift
    				break
    				;;
    		esac
    	done
    	
		# Handles (read-only)
		readonly _BOT_HANDLE_

    	[[ $data ]] || return 1 # vazio
   	
		IFS=':' read -r flag cmd <<< "${_BOT_HANDLE_[$data]}"

		case $flag in
			func) $cmd;;
			exec) eval "$cmd";;
		esac
    
    	# return
    	return 0
    }
    
    TeleBot.getWebhookInfo()
    {
    	# Local Variable
    	local jq_obj
	
		# Call the getMe method passing the API address, followed by the method name.
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.})
    	
    	# Check method return status
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	return $?
    }
    
    TeleBot.deleteWebhook()
    {
    	# Local Variable
    	local jq_obj
	
		# Call the getMe method passing the API address, followed by the method name.
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.})
    	
    	# Check method return status
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	return $?
    }
    
    TeleBot.setWebhook()
    {
    	local url certificate max_connections allowed_updates jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'u:c:m:a:' \
							 --longoptions 'url:, 
    										certificate:,
    										max_connections:,
    										allowed_updates:' \
    						 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-u|--url)
    				url=$2
    				shift 2
    				;;
    			-c|--certificate)
					CheckArgType file "$1" "$2"
    				certificate=$2
    				shift 2
    				;;
    			-m|--max_connections)
    				CheckArgType int "$1" "$2"
    				max_connections=$2
    				shift 2
    				;;
    			-a|--allowed_updates)
    				allowed_updates=$2
    				shift 2
    				;;
    			--)
    				shift 
    				break
    				;;
    		esac
    	done
    	
    	[[ $url ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --url]"
    
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${url:+-d url="$url"} \
									${certificate:+-d certificate="$certificate"} \
									${max_connections:+-d max_connections="$max_connections"} \
									${allowed_updates:+-d allowed_updates="$allowed_updates"})
    
    	# Test the method return.
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	# Status
    	return $?
    }	
    
    TeleBot.setChatPhoto()
    {
    	local chat_id photo jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:p:' \
							 --longoptions 'chat_id:,photo:' \
							 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-p|--photo)
					CheckArgType file "$1" "$2"
    				photo=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $photo ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-p, --photo]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
 									${photo:+-F photo="$photo"})
    
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    		
    	# Status
    	return $?
    }
    
    TeleBot.deleteChatPhoto()
    {
    	local chat_id jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:' \
							 --longoptions 'chat_id:' \
							 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
		# Status
    	return $?
    
    }
    
    TeleBot.setChatTitle()
    {
    	
    	local chat_id title jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:t:' \
							 --longoptions 'chat_id:,title:' \
							 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-t|--title)
    				title=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $title ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --title]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
 									${title:+-d title="$title"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
		# Status
    	return $?
    }
    
    
    TeleBot.setChatDescription()
    {
    	
    	local chat_id description jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:d:' \
							 --longoptions 'chat_id:,description:' \
							 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-d|--description)
    				description=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $description ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-d, --description]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
 									${description:+-d description="$description"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    		
    	# Status
    	return $?
    }
    
    TeleBot.pinChatMessage()
    {
    	
    	local chat_id message_id disable_notification jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:m:n:' \
							 --longoptions 'chat_id:,
											message_id:,
    										disable_notification:' \
    						 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-m|--message_id)
    				CheckArgType int "$1" "$2"
    				message_id=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;	
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
 									${message_id:+-d message_id="$message_id"} \
 									${disable_notification:+-d disable_notification="$disable_notification"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    		
    	# Status
    	return $?
    }
    
    TeleBot.unpinChatMessage()
    {
    	local chat_id jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:' \
							 --longoptions 'chat_id:' \
							 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    		
    	# Status
    	return $?
    }
    
    TeleBot.restrictChatMember()
    {
    	local chat_id user_id until_date permissions jq_obj
    
    	local param=$(getopt	--name "$FUNCNAME" \
								--options 'c:u:d:p:' \
								--longoptions 'chat_id:,
												user_id:,
												until_date:,
												permissions:' \
								-- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-u|--user_id)
    				CheckArgType int "$1" "$2"
    				user_id=$2
    				shift 2
    				;;
    			-d|--until_date)
    				CheckArgType int "$1" "$2"
    				until_date=$2
    				shift 2
    				;;
				-p|--permissions)
					permissions=$2
					shift 2
					;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
    	[[ $permissions ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-p, --permissions]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${user_id:+-d user_id="$user_id"} \
									${until_date:+-d until_date="$until_date"} \
									${permissions:+-d permissions="$permissions"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    		
    	# Status
    	return $?
    	
    }
    
    
    TeleBot.promoteChatMember()
    {
    	local	chat_id user_id can_change_info can_post_messages \
    			can_edit_messages can_delete_messages can_invite_users \
    			can_restrict_members can_pin_messages can_promote_members \
				jq_obj
    
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:u:i:p:e:d:v:r:f:m:' \
							 --longoptions 'chat_id:,
    										user_id:,
    										can_change_info:,
    										can_post_messages:,
    										can_edit_messages:,
    										can_delete_messages:,
    										can_invite_users:,
    										can_restrict_members:,
    										can_pin_messages:,
    										can_promote_members:' \
							 -- "$@")
    	
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-u|--user_id)
    				CheckArgType int "$1" "$2"
    				user_id=$2
    				shift 2
    				;;
    			-i|--can_change_info)
    				CheckArgType bool "$1" "$2"
    				can_change_info=$2
    				shift 2
    				;;
    			-p|--can_post_messages)
    				CheckArgType bool "$1" "$2"
    				can_post_messages=$2
    				shift 2
    				;;
    			-e|--can_edit_messages)
    				CheckArgType bool "$1" "$2"
    				can_edit_messages=$2
    				shift 2
    				;;
    			-d|--can_delete_messages)
    				CheckArgType bool "$1" "$2"
    				can_delete_messages=$2
    				shift 2
    				;;
    			-v|--can_invite_users)
    				CheckArgType bool "$1" "$2"
    				can_invite_users=$2
    				shift 2
    				;;
    			-r|--can_restrict_members)
    				CheckArgType bool "$1" "$2"
    				can_restrict_members=$2
    				shift 2
    				;;
    			-f|--can_pin_messages)
    				CheckArgType bool "$1" "$2"
    				can_pin_messages=$2
    				shift 2
    				;;	
    			-m|--can_promote_members)
    				CheckArgType bool "$1" "$2"
    				can_promote_members=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --user_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${user_id:+-d user_id="$user_id"} \
									${can_change_info:+-d can_change_info="$can_change_info"} \
									${can_post_messages:+-d can_post_messages="$can_post_messages"} \
									${can_edit_messages:+-d can_edit_messages="$can_edit_messages"} \
									${can_delete_messages:+-d can_delete_messages="$can_delete_messages"} \
									${can_invite_users:+-d can_invite_users="$can_invite_users"} \
									${can_restrict_members:+-d can_restrict_members="$can_restrict_members"} \
									${can_pin_messages:+-d can_pin_messages="$can_pin_messages"} \
									${can_promote_members:+-d can_promote_members="$can_promote_members"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    		
    	# Status
    	return $?
    }
    
    TeleBot.exportChatInviteLink()
    {
    	local chat_id jq_obj
    
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:' \
							 --longoptions 'chat_id:' \
							 -- "$@")
    	
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
    	
    	# Test the method return.
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    		
    	# Status
    	return $?
    }
    
    TeleBot.sendVideoNote()
    {
    	local chat_id video_note duration length disable_notification \
    			reply_to_message_id reply_markup jq_obj
    
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:v:t:l:n:r:k:' \
							 --longoptions 'chat_id:,
    										video_note:,
    										duration:,
    										length:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    	
    	# Define the positional parameters
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-v|--video_note)
					CheckArgType file "$1" "$2"
    				video_note=$2
    				shift 2
    				;;
    			-t|--duration)
    				CheckArgType int "$1" "$2"
    				duration=$2
    				shift 2
    				;;
    			-l|--length)
    				CheckArgType int "$1" "$2"
    				length=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]]		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $video_note ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-v, --video_note]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${video_note:+-F video_note="$video_note"} \
									${duration:+-F duration="$duration"} \
									${length:+-F length="$length"} \
									${disable_notification:+-F disable_notification="$disable_notification"} \
									${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
									${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Test the method return.
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	# Status
    	return $?
    }
    
    
    TeleBot.InlineKeyboardButton()
    {
        local 	__button __line __text __url __callback_data \
                __switch_inline_query __switch_inline_query_current_chat
    
        local __param=$(getopt 	--name "$FUNCNAME" \
							 	--options 'b:l:t:u:c:q:s:' \
							 	--longoptions 'button:,
												line:,
												text:,
												url:,
												callback_data:,
												switch_inline_query:,
												switch_inline_query_chat:' \
							 	-- "$@")
    
    	eval set -- "$__param"
    
    	while :
    	do
    		case $1 in
    			-b|--button)
    				# Pointer that receives the address of "button" with the definitions
    				# of the inserted button configuration.
					CheckArgType var "$1" "$2"
    				__button=$2
    				shift 2
    				;;
    			-l|--line)
    				CheckArgType int "$1" "$2"
					__line=$(($2-1))
    				shift 2
    				;;
    			-t|--text)
					__text=$(echo -e "$2")
    				shift 2
    				;;
    			-u|--url)
    				__url=$2
    				shift 2
    				;;
    			-c|--callback_data)
    				__callback_data=$2
    				shift 2
    				;;
    			-q|--switch_inline_query)
    				__switch_inline_query=$2
    				shift 2
    				;;
    			-s|--switch_inline_query_current_chat)
    				__switch_inline_query_current_chat=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    
    	[[ $__button ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-b, --button]"
    	[[ $__text ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --text]"
    	[[ $__callback_data ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --callback_data]"
    	[[ $__line ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-l, --line]"
    	
		__button=$__button[$__line]

		printf -v $__button '%s' "${!__button#[}"
		printf -v $__button '%s' "${!__button%]}"
		
		printf -v $__button '%s {"text": "%s", "callback_data": "%s", "url": "%s", "switch_inline_query": "%s", "switch_inline_query_current_chat": "%s"}' 	\
							"${!__button:+${!__button},}"																									\
							"${__text}"																														\
							"${__callback_data}"																											\
							"${__url}"																														\
							"${__switch_inline_query}"																										\
							"${__switch_inline_query_current_chat}"

		printf -v $__button '%s' "[${!__button}]"

    	return $?
    }
    
    TeleBot.InlineKeyboardMarkup()
    {
    	local __button __keyboard

        local __param=$(getopt 	--name "$FUNCNAME" \
							 	--options 'b:' \
							 	--longoptions 'button:' \
							 	-- "$@")
    
    	eval set -- "$__param"
    
    	while :
    	do
    		case $1 in
    			-b|--button)
    				# Pointer that receives the address of the "keyboard" variable with the definitions
    				# of button configuration inserted.
					CheckArgType var "$1" "$2"
    				__button="$2"
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $__button ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-b, --button]"
    
		__button=$__button[@]

		printf -v __keyboard '%s,' "${!__button}"
		printf -v __keyboard '%s' "${__keyboard%,}"

    	# Build the object structure + keyboard array, set the values and save the settings.
    	# By default all values are 'false' until set.
		printf '{"inline_keyboard": [%s]}' "${__keyboard}"
    
		return $?
    }
    
    TeleBot.answerCallbackQuery()
    {
    	local callback_query_id text show_alert url cache_time jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:t:s:u:e:' \
    						 --longoptions 'callback_query_id:,
    										text:,
    										show_alert:,
    										url:,
    										cache_time:' \
    						 -- "$@")
    
    
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--callback_query_id)
    				callback_query_id=$2
    				shift 2
    				;;
    			-t|--text)
					text=$(echo -e "$2")
    				shift 2
    				;;
    			-s|--show_alert)
    				# boolean
    				CheckArgType bool "$1" "$2"
    				show_alert=$2
    				shift 2
    				;;
    			-u|--url)
    				url=$2
    				shift 2
    				;;
    			-e|--cache_time)
    				# integer
    				CheckArgType int "$1" "$2"
    				cache_time=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $callback_query_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --callback_query_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${callback_query_id:+-d callback_query_id="$callback_query_id"} \
									${text:+-d text="$text"} \
									${show_alert:+-d show_alert="$show_alert"} \
									${url:+-d url="$url"} \
									${cache_time:+-d cache_time="$cache_time"})
    
		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
    }
    
    # Create object representing a custom keyboard with answer options
    TeleBot.ReplyKeyboardMarkup()
    {
    	# Local Variables
    	local __button __resize_keyboard __on_time_keyboard __selective __keyboard
    	
    	# Read the parameters of the function.
    	local __param=$(getopt 	--name "$FUNCNAME" \
							 	--options 'b:r:t:s:' \
    						 	--longoptions 'button:,
    										resize_keyboard:,
    										one_time_keyboard:,
    										selective:' \
    						 	-- "$@")
    	
    	# Turn function parameters into positional parameters
        #
     	# Example:
     	# --param1 arg1 --param2 arg2 --param3 arg3 ...
     	# 	$1 				$2 			$3
    	eval set -- "$__param"
    	
    	# Wait for parameters to be read
    	while :
    	do
    		# Read the first position parameter "$1"; If it is a valid parameter,
     		# save the argument value at position '$2' and shift it two positions to the left (shift 2); Repeat the process
     		# until the value of '$1' equals '--' and ends the loop.
    		case $1 in
    			-b|--button)
					CheckArgType var "$1" "$2"
    				__button=$2
    				shift 2
    				;;
    			-r|--resize_keyboard)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				__resize_keyboard=$2
    				shift 2
    				;;
    			-t|--one_time_keyboard)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				__on_time_keyboard=$2
    				shift 2
    				;;
    			-s|--selective)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				__selective=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Print error message if required parameter is omitted.
    	[[ $__button ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-b, --button]"
		
		__button=$__button[@]

		printf -v __keyboard '%s,' "${!__button}"
		printf -v __keyboard '%s' "${__keyboard%,}"

    	# Build the object structure + keyboard array, set the values and save the settings.
    	# By default all values are 'false' until set.
		printf '{"keyboard": [%s], "resize_keyboard": %s, "one_time_keyboard": %s, "selective": %s}'	\
				"${__keyboard}"																			\
				"${__resize_keyboard:-false}" 															\
				"${__on_time_keyboard:-false}"															\
				"${__selective:-false}"

    	# status
    	return $?
    }

	TeleBot.KeyboardButton()
	{
		local __text __contact __location __button __line __request_poll

		local __param=$(getopt	--name "$FUNCNAME"	\
								--options 'b:l:t:c:o:r:'	\
								--longoptions 'button:,
												line:,
												text:,
												request_contact:,
												request_location:,
												request_poll:' \
								-- "$@")
	
		eval set -- "$__param"
	
		while :
		do
			case $1 in
				-b|--button)
					CheckArgType var "$1" "$2"
					__button=$2
					shift 2
					;;
				-l|--line)
					CheckArgType int "$1" "$2"
					__line=$(($2-1))
					shift 2
					;;
				-t|--text)
					__text=$(echo -e "$2")
					shift 2
					;;
				-c|--request_contact)
					CheckArgType bool "$1" "$2"
					__contact=$2
					shift 2
					;;
				-o|--request_location)
					CheckArgType bool "$1" "$2"
					__location=$2
					shift 2
					;;
				-r|--request_poll)
					__request_poll=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

    	[[ $__button ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-b, --button]"
    	[[ $__text ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --text]"
    	[[ $__line ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-l, --line]"
    
		__button=$__button[$__line]

		printf -v $__button '%s' "${!__button#[}"
		printf -v $__button '%s' "${!__button%]}"
		
		printf -v $__button '%s {"text": "%s", "request_contact": %s, "request_location": %s, "request_poll": %s}' 	\
							"${!__button:+${!__button},}"															\
							"${__text}"																				\
							"${__contact:-false}"																	\
							"${__location:-false}"																	\
							"${__request_poll:-\"\"}"

		printf -v $__button '%s' "[${!__button}]"

    	return $?
	}
	
	TeleBot.ForceReply()
	{
		local selective

		local param=$(getopt 	--name "$FUNCNAME" 			\
								--options 's:' 				\
								--longoptions 'selective:' 	\
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-s|--selective)
					CheckArgType bool "$1" "$2"
					selective=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		printf '{"force_reply": true, "selective": %s}' ${selective:-false}

		return $?
	}

	TeleBot.ReplyKeyboardRemove()
	{
		local selective

		local param=$(getopt 	--name "$FUNCNAME" 			\
								--options 's:' 				\
								--longoptions 'selective:' 	\
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-s|--selective)
					CheckArgType bool "$1" "$2"
					selective=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		printf '{"remove_keyboard": true, "selective": %s}' ${selective:-false}

		return $?
	}

    # Send Message
    TeleBot.sendMessage()
    {
    	# Local Variables 
    	local chat_id text parse_mode disable_web_page_preview
		local disable_notification reply_to_message_id reply_markup jq_obj
    	
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:t:p:w:n:r:k:' \
							 --longoptions 'chat_id:,
    										text:,
    										parse_mode:,
    										disable_web_page_preview:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    	# Define the positional parameters
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-t|--text)
					text=$(echo -e "$2")
    				shift 2
    				;;
    			-p|--parse_mode)
    				# Type: "markdown" or "html"
    				parse_mode=$2
    				shift 2
    				;;
    			-w|--disable_web_page_preview)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_web_page_preview=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    
    	# Required parameters.
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $text ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --text]"
    
    	# Call the API method, using the specified request command; The parameters
     	# and values are passed on the form and read by the method. The method return is redirected to the 'update.Json' file.
     	# Variables with null values are ignored and consequently the respective parameters omitted.
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${text:+-d text="$text"} \
									${parse_mode:+-d parse_mode="$parse_mode"} \
									${disable_web_page_preview:+-d disable_web_page_preview="$disable_web_page_preview"} \
									${disable_notification:+-d disable_notification="$disable_notification"} \
									${reply_to_message_id:+-d reply_to_message_id="$reply_to_message_id"} \
									${reply_markup:+-d reply_markup="$reply_markup"})
   
    	# Test the method return.
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	# Status
    	return $?
    }
    
    # Function to forward messages of any Type.
    TeleBot.forwardMessage()
    {
    	# Local Variables
    	local chat_id form_chat_id disable_notification message_id jq_obj
    	
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:f:n:m:' \
    						 --longoptions 'chat_id:,
    										from_chat_id:,
    										disable_notification:,
    										message_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id="$2"
    				shift 2
    				;;
    			-f|--from_chat_id)
    				from_chat_id="$2"
    				shift 2
    				;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification="$2"
    				shift 2
    				;;
    			-m|--message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				message_id="$2"
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters.
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $from_chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-f, --from_chat_id]"
    	[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
    
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${from_chat_id:+-d from_chat_id="$from_chat_id"} \
									${disable_notification:+-d disable_notification="$disable_notification"} \
									${message_id:+-d message_id="$message_id"})
    	
    	# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# status
    	return $?
    }
    
    # Use this function to send photos.
    TeleBot.sendPhoto()
    {
    	# Local Variables
    	local chat_id photo caption disable_notification 
		local parse_mode reply_to_message_id reply_markup jq_obj

    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:p:t:m:n:r:k:' \
    						 --longoptions 'chat_id:, 
    										photo:,
    										caption:,
											parse_mode:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-p|--photo)
					CheckArgType file "$1" "$2"
    				photo=$2
    				shift 2
    				;;
    			-t|--caption)
    				# Maximum character limit: 200
					caption=$(echo -e "$2")
    				shift 2
    				;;
				-m|--parse_mode)
					parse_mode=$2
					shift 2
					;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $photo ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-p, --photo]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${photo:+-F photo="$photo"} \
									${caption:+-F caption="$caption"} \
									${parse_mode:+-F parse_mode="$parse_mode"} \
									${disable_notification:+-F disable_notification="$disable_notification"} \
									${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
									${reply_markup:+-F reply_markup="$reply_markup"})
    	
    	# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    }
    
    # Use this function to send audio files.
    TeleBot.sendAudio()
    {
    	# Local Variables
    	local chat_id audio caption duration performer title 
		local parse_mode disable_notification reply_to_message_id reply_markup jq_obj
    	
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:a:t:m:d:e:i:n:r:k' \
    						 --longoptions 'chat_id:,
    										audio:,
    										caption:,
											parse_mode:,
    										duration:,
    										performer:,
    										title:,
    										disable_notification:,
    										reply_to_message_id:,	
    										reply_markup:' \
    						 -- "$@")
    
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-a|--audio)
					CheckArgType file "$1" "$2"
    				audio=$2
    				shift 2
    				;;
    			-t|--caption)
					caption=$(echo -e "$2")
    				shift 2
    				;;
				-m|--parse_mode)
					parse_mode=$2
					shift 2
					;;
    			-d|--duration)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				duration=$2
    				shift 2
    				;;
    			-e|--performer)
    				performer=$2
    				shift 2
    				;;
    			-i|--title)
    				title=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $audio ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-a, --audio]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${audio:+-F audio="$audio"} \
									${caption:+-F caption="$caption"} \
									${parse_mode:+-F parse_mode="$parse_mode"} \
									${duration:+-F duration="$duration"} \
									${performer:+-F performer="$performer"} \
									${title:+-F title="$title"} \
									${disable_notification:+-F disable_notification="$disable_notification"} \
									${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
									${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    		
    }
    
    # Use this function to send documents.
    TeleBot.sendDocument()
    {
    	# Local Variables
    	local chat_id document caption disable_notification 
		local parse_mode reply_to_message_id reply_markup jq_obj
    	
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:d:t:m:n:r:k:' \
    						 --longoptions 'chat_id:,
											document:,
    										caption:,
											parse_mode:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-d|--document)
					CheckArgType file "$1" "$2"
    				document=$2
    				shift 2
    				;;
    			-t|--caption)
					caption=$(echo -e "$2")
    				shift 2
    				;;
				-m|--parse_mode)
					parse_mode=$2
					shift 2
					;;
    			-n|--disable_notification)
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $document ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-d, --document]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${document:+-F document="$document"} \
									${caption:+-F caption="$caption"} \
									${parse_mode:+-F parse_mode="$parse_mode"} \
									${disable_notification:+-F disable_notification="$disable_notification"} \
									${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
									${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    	
    }
    
    # Use this function to send stickers
    TeleBot.sendSticker()
    {
    	# Local Variables
    	local chat_id sticker disable_notification reply_to_message_id reply_markup jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:s:n:r:k:' \
    						 --longoptions 'chat_id:,
    										sticker:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-s|--sticker)
					CheckArgType file "$1" "$2"
    				sticker=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $sticker ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --sticker]"
    
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${sticker:+-F sticker="$sticker"} \
									${disable_notification:+-F disable_notification="$disable_notification"} \
									${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
									${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    }
   
	TeleBot.getStickerSet()
	{
		local name jq_obj
		
		local param=$(getopt --name "$FUNCNAME" \
							 --options 'n:' \
							 --longoptions 'name:' \
							 -- "$@")
		
		# Positional parameters
		eval set -- "$param"

		while :
		do
			case $1 in
				-n|--name)
					name=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done
    	
		[[ $name ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-n, --name]"
    	
		jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} ${name:+-d name="$name"})
    
		# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
	} 
	
	TeleBot.uploadStickerFile()
	{
		local user_id png_sticker jq_obj
		
		local param=$(getopt --name "$FUNCNAME" \
							 --options 'u:s:' \
							 --longoptions 'user_id:,
											png_sticker:' \
							 -- "$@")
		
		eval set -- "$param"
		
		while :
		do
			case $1 in
				-u|--user_id)
    				CheckArgType int "$1" "$2"
					user_id=$2
					shift 2
					;;
				-s|--png_sticker)
					CheckArgType file "$1" "$2"
					png_sticker=$2
					shift 2
					;;
				--)
					shift
					break
					;;
				esac
		done

		[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
		[[ $png_sticker ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --png_sticker]"
    	
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${user_id:+-F user_id="$user_id"} \
									${png_sticker:+-F png_sticker="$png_sticker"})
    	
		# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
					
	}

	TeleBot.setStickerPositionInSet()
	{
		local sticker position jq_obj

		local param=$(getopt --name "$FUNCNAME" \
							 --options 's:p:' \
							 --longoptions 'sticker:,
											position:' \
							 -- "$@")
		
		eval set -- "$param"

		while :
		do
			case $1 in
				-s|--sticker)
					sticker=$2
					shift 2
					;;
				-p|--position)
					CheckArgType int "$1" "$2"
					position=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done
		
		[[ $sticker ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --sticker]"
		[[ $position ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-p, --position]"
    	
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${sticker:+-d sticker="$sticker"} \
									${position:+-d position="$position"})
    	
		# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
		# Status
    	return $?
				
	}
	
	TeleBot.deleteStickerFromSet()
	{
		local sticker jq_obj

		local param=$(getopt --name "$FUNCNAME" \
							 --options 's:' \
							 --longoptions 'sticker:' \
							 -- "$@")
		
		eval set -- "$param"

		while :
		do
			case $1 in
				-s|--sticker)
					sticker=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done
		
		[[ $sticker ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --sticker]"
    	
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} ${sticker:+-d sticker="$sticker"})
    	
		# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
		# Status
    	return $?
				
	}
	
	TeleBot.stickerMaskPosition()
	{

		local point x_shift y_shift scale zoom
		
		local param=$(getopt --name "$FUNCNAME" \
							 --options 'p:x:y:s:z:' \
							 --longoptions 'point:,
											x_shift:,
											y_shift:,
											scale:,
											zoom:' \
							 -- "$@")

		eval set -- "$param"
		
		while :
		do
			case $1 in
				-p|--point)
					point=$2
					shift 2
					;;
				-x|--x_shift)
					CheckArgType float "$1" "$2"
					x_shift=$2
					shift 2
					;;
				-y|--y_shift)
					CheckArgType float "$1" "$2"
					y_shift=$2
					shift 2
					;;
				-s|--scale)
					CheckArgType float "$1" "$2"
					scale=$2
					shift 2
					;;
				-z|--zoom)
					CheckArgType float "$1" "$2"
					zoom=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done
		
		[[ $point ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-p, --point]"
		[[ $x_shift ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-x, --x_shift]"
		[[ $y_shift ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-y, --y_shift]"
		[[ $scale ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --scale]"
		[[ $zoom ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-z, --zoom]"
		
		cat << _EOF
{ "point": "$point", "x_shift": $x_shift, "y_shift": $y_shift, "scale": $scale, "zoom": $zoom }
_EOF

	return 0

	}

	TeleBot.createNewStickerSet()
	{
		local user_id name title png_sticker emojis contains_masks mask_position jq_obj
		
		local param=$(getopt --name "$FUNCNAME" \
							 --options 'u:n:t:s:e:c:m:' \
							 --longoptions 'user_id:,
											name:,
											title:,
											png_sticker:,
											emojis:,
											contains_mask:,
											mask_position:' \
							 -- "$@")

		eval set -- "$param"
		
		while :
		do
			case $1 in
				-u|--user_id)
					CheckArgType int "$1" "$2"
					user_id=$2
					shift 2
					;;
				-n|--name)
					name=$2
					shift 2
					;;
				-t|--title)
					title=$2
					shift 2
					;;
				-s|--png_sticker)
					CheckArgType file "$1" "$2"
					png_sticker=$2
					shift 2
					;;
				-e|--emojis)
					emojis=$2
					shift 2
					;;
				-c|--contains_masks)
    				CheckArgType bool "$1" "$2"
					contains_masks=$2
					shift 2
					;;
				-m|--mask_position)
					mask_position=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done
		
		[[ $user_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
		[[ $name ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-n, --name]"
		[[ $title ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --title]"
		[[ $png_sticker ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --png_sticker]"
		[[ $emojis ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-e, --emojis]"
	
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${user_id:+-F user_id="$user_id"} \
									${name:+-F name="$name"} \
									${title:+-F title="$title"} \
									${png_sticker:+-F png_sticker="$png_sticker"} \
									${emojis:+-F emojis="$emojis"} \
									${contains_masks:+-F contains_masks="$contains_masks"} \
									${mask_position:+-F mask_position="$mask_position"})
    	
		# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
		# Status
    	return $?
			
	}
	
	TeleBot.addStickerToSet()
	{
		local user_id name png_sticker emojis mask_position jq_obj
		
		local param=$(getopt --name "$FUNCNAME" \
							 --options 'u:n:s:e:m:' \
							 --longoptions 'user_id:,
											name:,
											png_sticker:,
											emojis:,
											mask_position:' \
							 -- "$@")

		eval set -- "$param"
		
		while :
		do
			case $1 in
				-u|--user_id)
					CheckArgType int "$1" "$2"
					user_id=$2
					shift 2
					;;
				-n|--name)
					name=$2
					shift 2
					;;
				-s|--png_sticker)
					CheckArgType file "$1" "$2"
					png_sticker=$2
					shift 2
					;;
				-e|--emojis)
					emojis=$2
					shift 2
					;;
				-m|--mask_position)
					mask_position=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done
		
		[[ $user_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
		[[ $name ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-n, --name]"
		[[ $png_sticker ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --png_sticker]"
		[[ $emojis ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-e, --emojis]"
	
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${user_id:+-F user_id="$user_id"} \
									${name:+-F name="$name"} \
									${png_sticker:+-F png_sticker="$png_sticker"} \
									${emojis:+-F emojis="$emojis"} \
									${mask_position:+-F mask_position="$mask_position"})
    	
		# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
		# Status
    	return $?
			
	}

    # Function to send video files.
    TeleBot.sendVideo()
    {
    	# Local Variables
    	local chat_id video duration width height caption disable_notification
		local parse_mode reply_to_message_id reply_markup jq_obj supports_streaming
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:v:d:w:h:t:m:n:r:k:s:' \
							 --longoptions 'chat_id:,
    										video:,
    										duration:,
    										width:,
    										height:,
    										caption:,
											parse_mode:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:,
											supports_streaming:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-v|--video)
					CheckArgType file "$1" "$2"
    				video=$2
    				shift 2
    				;;
    			-d|--duration)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				duration=$2
    				shift 2
    				;;
    			-w|--width)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				width=$2
    				shift 2
    				;;
    			-h|--height)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				height=$2
    				shift 2
    				;;
    			-t|--caption)
					caption=$(echo -e "$2")
    				shift 2
    				;;
				-m|--parse_mode)
					parse_mode=$2
					shift 2
					;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
				-s|--supports_streaming)
    				CheckArgType bool "$1" "$2"
					supports_streaming=$2
					shift 2
					;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters.
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $video ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-v, --video]"
    
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${video:+-F video="$video"} \
									${duration:+-F duration="$duration"} \
									${width:+-F width="$width"} \
									${height:+-F height="$height"} \
									${caption:+-F caption="$caption"} \
									${parse_mode:+-F parse_mode="$parse_mode"} \
									${disable_notification:+-F disable_notification="$disable_notification"} \
    								${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
    								${reply_markup:+-F reply_markup="$reply_markup"} \
									${supports_streaming:+-F supports_streaming="$supports_streaming"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    	
    }
    
    # Function to send audio.
    TeleBot.sendVoice()
    {
    	# Local Variables
    	local chat_id voice caption duration disable_notification 
		local parse_mode reply_to_message_id reply_markup jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:v:t:m:d:n:r:k:' \
    						 --longoptions 'chat_id:,
    										voice:,
    										caption:,
											parse_mode:,
    										duration:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-v|--voice)
					CheckArgType file "$1" "$2"
    				voice=$2
    				shift 2
    				;;
    			-t|--caption)
					caption=$(echo -e "$2")
    				shift 2
    				;;
				-m|--parse_mode)
					parse_mode=$2
					shift 2
					;;
    			-d|--duration)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				duration=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
					;;
    		esac
    	done
    	
    	# Required parameters.
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $voice ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-v, --voice]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
    								${voice:+-F voice="$voice"} \
    								${caption:+-F caption="$caption"} \
									${parse_mode:+-F parse_mode="$parse_mode"} \
    								${duration:+-F duration="$duration"} \
    								${disable_notification:+-F disable_notification="$disable_notification"} \
    								${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
    								${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    	
    }
    
    # Function used to send a location using latitude and longitude coordinates.
    TeleBot.sendLocation()
    {
    	# Local Variables
    	local chat_id latitude longitude live_period
		local disable_notification reply_to_message_id reply_markup jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:l:g:p:n:r:k:' \
    						 --longoptions 'chat_id:,
    										latitude:,
    										longitude:,
											live_period:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-l|--latitude)
    				# Type: float
    				CheckArgType float "$1" "$2"
    				latitude=$2
    				shift 2
    				;;
    			-g|--longitude)
    				# Type: float
    				CheckArgType float "$1" "$2"
    				longitude=$2
    				shift 2
    				;;
				-p|--live_period)
    				CheckArgType int "$1" "$2"
					live_period=$2
					shift 2
					;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
					;;
    		esac
    	done
    	
    	# Required parameters
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $latitude ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-l, --latitude]"
    	[[ $longitude ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-g, --longitude]"
    			
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
    								${latitude:+-F latitude="$latitude"} \
    								${longitude:+-F longitude="$longitude"} \
									${live_period:+-F live_period="$live_period"} \
    								${disable_notification:+-F disable_notification="$disable_notification"} \
    								${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
    								${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
    	
    }
    
    # Function used to send details of a location.
    TeleBot.sendVenue()
    {
    	# Local Variables
    	local chat_id latitude longitude title address foursquare_id disable_notification reply_to_message_id reply_markup jq_obj
    	
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:l:g:i:a:f:n:r:k:' \
    						 --longoptions 'chat_id:,
    										latitude:,
    										longitude:,
    										title:,
    										address:,
    										foursquare_id:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    	# Define the positional parameters
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-l|--latitude)
    				# Type: float
    				CheckArgType float "$1" "$2"
    				latitude=$2
    				shift 2
    				;;
    			-g|--longitude)
    				# Type: float
    				CheckArgType float "$1" "$2"
    				longitude=$2
    				shift 2
    				;;
    			-i|--title)
    				title=$2
    				shift 2
    				;;
    			-a|--address)
    				address=$2
    				shift 2
    				;;
    			-f|--foursquare_id)
    				foursquare_id=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
					;;
    		esac
    	done
    			
    	# Required parameters.
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $latitude ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-l, --latitude]"
    	[[ $longitude ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-g, --longitude]"
    	[[ $title ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-i, --title]"
    	[[ $address ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-a, --address]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
    								${latitude:+-F latitude="$latitude"} \
    								${longitude:+-F longitude="$longitude"} \
    								${title:+-F title="$title"} \
    								${address:+-F address="$address"} \
    								${foursquare_id:+-F foursquare_id="$foursquare_id"} \
    								${disable_notification:+-F disable_notification="$disable_notification"} \
    								${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
    								${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    }
    
    # Use this function to send a contact + number
    TeleBot.sendContact()
    {
    	# Local Variables
    	local chat_id phone_number first_name last_name disable_notification reply_to_message_id reply_markup jq_obj
    	
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:p:f:l:n:r:k:' \
    						 --longoptions 'chat_id:,
    										phone_number:,
    										first_name:,
    										last_name:,
    										disable_notification:,
    										reply_to_message_id:,
    										reply_markup:' \
    						 -- "$@")
    
    
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-p|--phone_number)
    				phone_number=$2
    				shift 2
    				;;
    			-f|--first_name)
    				first_name=$2
    				shift 2
    				;;
    			-l|--last_name)
    				last_name=$2
    				shift 2
    				;;
    			-n|--disable_notification)
    				# Type: boolean
    				CheckArgType bool "$1" "$2"
    				disable_notification=$2
    				shift 2
    				;;
    			-r|--reply_to_message_id)
    				# Type: Integer
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
    				;;
    			-k|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
					;;
    		esac
    	done
    	
    	# Required parameters.	
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $phone_number ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-p, --phone_number]"
    	[[ $first_name ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-f, --first_name]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
    								${phone_number:+-F phone_number="$phone_number"} \
    								${first_name:+-F first_name="$first_name"} \
    								${last_name:+-F last_name="$last_name"} \
    								${disable_notification:+-F disable_notification="$disable_notification"} \
    								${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
    								${reply_markup:+-F reply_markup="$reply_markup"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    }
    
    # Send an action to bot.
    TeleBot.sendChatAction()
    {
    	# Local Variables
    	local chat_id action jq_obj
    	
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:a:' \
    						 --longoptions 'chat_id:,
    										action:' \
    						 -- "$@")
    
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-a|--action)
    				action=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
					;;
    		esac
    	done
    
    	# Required parameters.		
    	[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $action ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-a, --action]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${action:+-d action="$action"})
    	
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    }
    
    # Use this function to get photos of a specific user.
    TeleBot.getUserProfilePhotos()
    {
    	# Local Variables 
    	local user_id offset limit ind last index max item total jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'u:o:l:' \
    						 --longoptions 'user_id:,
    										offset:,
    										limit:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    	
    	while :
    	do
    		case $1 in
    			-u|--user_id)
    				CheckArgType int "$1" "$2"
    				user_id=$2
    				shift 2
    				;;
    			-o|--offset)
    				CheckArgType int "$1" "$2"
    				offset=$2
    				shift 2
    				;;
    			-l|--limit)
    				CheckArgType int "$1" "$2"
    				limit=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters.
    	[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} \
									${user_id:+-d user_id="$user_id"} \
									${offset:+-d offset="$offset"} \
									${limit:+-d limit="$limit"})
  
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	# Status
    	return $?
    }
    
    # Function to list information from the specified file.
    TeleBot.getFile()
    {
    	# Local Variables
    	local file_id jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'f:' \
    						 --longoptions 'file_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-f|--file_id)
    				file_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters.
    	[[ $file_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-f, --file_id]"
    	
    	# Call the method.
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} ${file_id:+-d file_id="$file_id"})
    
    	# Test the method return.
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    }		
    
    # This function kicks the user from the chat or channel. (administrators only)
    TeleBot.kickChatMember()
    {
    	# Local Variables
    	local chat_id user_id until_date jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:u:d:' \
    						 --longoptions 'chat_id:,
    										user_id:,
    										until_date:' \
    						 -- "$@")
    
    	# Define the positional parameters
    	eval set -- "$param"
    
    	# Handle the parameters
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-u|--user_id)
    				CheckArgType int "$1" "$2"
    				user_id=$2
    				shift 2
    				;;
    			-d|--until_date)
    				CheckArgType int "$1" "$2"
    				until_date=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	# Required parameters.
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
    	
    	# Call the method
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
    								${user_id:+-d user_id="$user_id"} \
    								${until_date:+-d until_date="$until_date"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
    }
    
    # Use this function to remove the bot from the group or channel.
    TeleBot.leaveChat()
    {
    	# Local Variables
    	local chat_id jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:' \
    						 --longoptions 'chat_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
    	
    }
    
    TeleBot.unbanChatMember()
    {
    	local chat_id user_id jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:u:' \
    						 --longoptions 'chat_id:,
    										user_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-u|--user_id)
    				CheckArgType int "$1" "$2"
    				user_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
    								${user_id:+-d user_id="$user_id"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
    }
    
    TeleBot.getChat()
    {
    	# Local Variables
    	local chat_id jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:' \
    						 --longoptions 'chat_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	# Status
    	return $?
    }
    
    TeleBot.getChatAdministrators()
    {
    	local chat_id total key index jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:' \
    						 --longoptions 'chat_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status	
    	return $?
    }
    
    TeleBot.getChatMembersCount()
    {
    	local chat_id jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:' \
    						 --longoptions 'chat_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
    }
    
    TeleBot.getChatMember()
    {
    	# Local Variables
    	local chat_id user_id jq_obj
    
    	# Read the parameters of the function
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:u:' \
    						 --longoptions 'chat_id:,
    						 				user_id:' \
    						 -- "$@")
    
    	
    	# Define the positional parameters
    	eval set -- "$param"
    
    	while :
    	do
    		case $1 in
    			-c|--chat_id)
    				chat_id=$2
    				shift 2
    				;;
    			-u|--user_id)
    				CheckArgType int "$1" "$2"
    				user_id=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
    				;;
    		esac
    	done
    	
    	[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ GET $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
    								${user_id:+-d user_id="$user_id"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
    }
    
    TeleBot.editMessageText()
    {
    	local chat_id message_id inline_message_id text parse_mode disable_web_page_preview reply_markup jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:m:i:t:p:w:r:' \
    						 --longoptions 'chat_id:,
    										message_id:,
    										inline_message_id:,
    										text:,
    										parse_mode:,
    										disable_web_page_preview:,
    										reply_markup:' \
    						 -- "$@")
    	
    	eval set -- "$param"
    
    	while :
    	do
    			case $1 in
    				-c|--chat_id)
    					chat_id=$2
    					shift 2
    					;;
    				-m|--message_id)
    					CheckArgType int "$1" "$2"
    					message_id=$2
    					shift 2
    					;;
    				-i|--inline_message_id)
    					CheckArgType int "$1" "$2"
    					inline_message_id=$2
    					shift 2
    					;;
    				-t|--text)
						text=$(echo -e "$2")
    					shift 2
    					;;
    				-p|--parse_mode)
    					parse_mode=$2
    					shift 2
    					;;
    				-w|--disable_web_page_preview)
    					CheckArgType bool "$1" "$2"
    					disable_web_page_preview=$2
    					shift 2
    					;;
    				-r|--reply_markup)
    					reply_markup=$2
    					shift 2
    					;;
    				--)
    					shift
    					break
						;;
    			esac
    	done
    	
    	[[ $text ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --text]"
		[[ $inline_message_id ]] && unset chat_id message_id || {
			[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
			[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
		}
    	
    
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
    								${message_id:+-d message_id="$message_id"} \
    								${inline_message_id:+-d inline_message_id="$inline_message_id"} \
    								${text:+-d text="$text"} \
    								${parse_mode:+-d parse_mode="$parse_mode"} \
    								${disable_web_page_preview:+-d disable_web_page_preview="$disable_web_page_preview"} \
    								${reply_markup:+-d reply_markup="$reply_markup"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	return $?
    	
    }
    
    TeleBot.editMessageCaption()
    {
    	local chat_id message_id inline_message_id 
		local parse_mode caption reply_markup jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:m:i:t:p:r:' \
    						 --longoptions 'chat_id:,
    										message_id:,
    										inline_message_id:,
    										caption:,
											parse_mode:,
    										reply_markup:' \
    						 -- "$@")
    	
    	eval set -- "$param"
    
    	while :
    	do
    			case $1 in
    				-c|--chat_id)
    					chat_id=$2
    					shift 2
    					;;
    				-m|--message_id)
    					CheckArgType int "$1" "$2"
    					message_id=$2
    					shift 2
    					;;
    				-i|--inline_message_id)
    					CheckArgType int "$1" "$2"
    					inline_message_id=$2
    					shift 2
    					;;
    				-t|--caption)
						caption=$(echo -e "$2")
    					shift 2
    					;;
					-p|--parse_mode)
						parse_mode=$2
						shift 2
						;;
    				-r|--reply_markup)
    					reply_markup=$2
    					shift 2
    					;;
    				--)
    					shift
    					break
						;;
    			esac
    	done
    				
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
    	
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
    								${message_id:+-d message_id="$message_id"} \
    								${inline_message_id:+-d inline_message_id="$inline_message_id"} \
    								${caption:+-d caption="$caption"} \
									${parse_mode:+-d parse_mode="$parse_mode"} \
    								${reply_markup:+-d reply_markup="$reply_markup"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	return $?
    	
    }
    
    TeleBot.editMessageReplyMarkup()
    {
    	local chat_id message_id inline_message_id reply_markup jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:m:i:r:' \
    						 --longoptions 'chat_id:,
    										message_id:,
    										inline_message_id:,
    										reply_markup:' \
    						 -- "$@")
    	
    	eval set -- "$param"
    
    	while :
    	do
    			case $1 in
    				-c|--chat_id)
    					chat_id=$2
    					shift 2
    					;;
    				-m|--message_id)
    					CheckArgType int "$1" "$2"
    					message_id=$2
    					shift 2
    					;;
    				-i|--inline_message_id)
    					CheckArgType int "$1" "$2"
    					inline_message_id=$2
    					shift 2
    					;;
    				-r|--reply_markup)
    					reply_markup=$2
    					shift 2
    					;;
    				--)
    					shift
    					break
						;;
    			esac
    	done
		
		[[ $inline_message_id ]] && unset chat_id message_id || {
			[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
			[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
		}
    
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
    								${message_id:+-d message_id="$message_id"} \
     								${inline_message_id:+-d inline_message_id="$inline_message_id"} \
    								${reply_markup:+-d reply_markup="$reply_markup"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	return $?
    	
    }
    
    TeleBot.deleteMessage()
    {
    	local chat_id message_id jq_obj
    	
    	local param=$(getopt --name "$FUNCNAME" \
							 --options 'c:m:' \
    						 --longoptions 'chat_id:,
    										message_id:' \
    						 -- "$@")
    	
    	eval set -- "$param"
    
    	while :
    	do
    			case $1 in
    				-c|--chat_id)
    					chat_id=$2
    					shift 2
    					;;
    				-m|--message_id)
    					CheckArgType int "$1" "$2"
    					message_id=$2
    					shift 2
    					;;
    				--)
    					shift
    					break
						;;
    			esac
    	done
    	
    	[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
    	[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
    
    	jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
    								${message_id:+-d message_id="$message_id"})
    
    	# Check for errors during the method call
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	return $?
    
    }
   
	TeleBot.downloadFile()
	{
		local file_path dir ext file jq_obj
		local uri="https://api.telegram.org/file/bot$_TOKEN_"

		local param=$(getopt --name "$FUNCNAME" \
								--options 'f:d:' \
								--longoptions 'file_path:,
												dir:' \
								-- "$@")
		
		eval set -- "$param"

		while :
		do
			case $1 in
				-f|--file_path)
					[[ $2 =~ \.[^.]+$ ]]
					ext=$BASH_REMATCH
					file_path=$2
					shift 2
					;;
				-d|--dir)
					[[ -d $2 ]] || MessageError API "$_ERR_DIR_NOT_FOUND_" "$1" "$2"
					[[ -w $2 ]] || MessageError API "$_ERR_DIR_WRITE_DENIED_" "$1" "$2"
					dir=${2%/}
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		[[ $file_path ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-f, --file_path]"
		[[ $dir ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-d, --dir]"

		# Generate the file name appending the creation time.
		file=file$(date +%d%m%Y%H%M%S%N)${ext:-.dat}

		# Download the specified uri and return a json object
		# with process information. If successful, the directory
		# destination is returned, otherwise an error message is displayed.
		if wget -qO "$dir/$file" "$uri/$file_path"; then
			# Success
			printf -v jq_obj '{"ok":true,"result":{"file_path":"%s"}}' "$dir/$file"
		else
			# Failure
			printf -v jq_obj '{"ok":false,"error_code":404,"description":"Bad Request: file not found"}'
			rm -f "$dir/$file" 2>/dev/null # Remove invalid file.
		fi

		MethodReturn "$jq_obj" || MessageError TG "$jq_obj"

		return $?
	}

	TeleBot.editMessageLiveLocation()
	{
		local chat_id message_id inline_message_id
		local latitude longitude reply_markup jq_obj
		
		local param=$(getopt --name "$FUNCNAME" \
								--options 'c:m:i:l:g:r:' \
								--longoptions 'chat_id:,
												message_id:,
												inline_message_id:,
												latitude:,
												longitude:,
												reply_markup:' \
								-- "$@")
		
		eval set -- "$param"

		while :
		do
			case $1 in
				-c|--chat_id)
					chat_id=$2
					shift 2
					;;
				-m|--message_id)
    				CheckArgType int "$1" "$2"
					message_id=$2
					shift 2
					;;
    			-i|--inline_message_id)
					CheckArgType int "$1" "$2"
					inline_message_id=$2
					shift 2
					;;
    			-l|--latitude)
    				# Type: float
    				CheckArgType float "$1" "$2"
    				latitude=$2
    				shift 2
    				;;
    			-g|--longitude)
    				# Type: float
    				CheckArgType float "$1" "$2"
    				longitude=$2
    				shift 2
    				;;
    			-r|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
					;;
			esac
		done
	
		[[ $inline_message_id ]] && unset chat_id message_id || {
			[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
			[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
		}
    	
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${message_id:+-d message_id="$message_id"} \
									${inline_message_id:+-d inline_message_id="$inline_message_id"} \
    								${latitude:+-d latitude="$latitude"} \
    								${longitude:+-d longitude="$longitude"} \
    								${reply_markup:+-d reply_markup="$reply_markup"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
	}	

	TeleBot.stopMessageLiveLocation()
	{
		local chat_id message_id inline_message_id reply_markup jq_obj
		
		local param=$(getopt --name "$FUNCNAME" \
								--options 'c:m:i:r:' \
								--longoptions 'chat_id:,
												message_id:,
												inline_message_id:,
												reply_markup:' \
								-- "$@")
		
		eval set -- "$param"

		while :
		do
			case $1 in
				-c|--chat_id)
					chat_id=$2
					shift 2
					;;
				-m|--message_id)
    				CheckArgType int "$1" "$2"
					message_id=$2
					shift 2
					;;
    			-i|--inline_message_id)
					CheckArgType int "$1" "$2"
					inline_message_id=$2
					shift 2
					;;
    			-r|--reply_markup)
    				reply_markup=$2
    				shift 2
    				;;
    			--)
    				shift
    				break
					;;
			esac
		done
	
		[[ $inline_message_id ]] && unset chat_id message_id || {
			[[ $chat_id ]] 		|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
			[[ $message_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --message_id]"
		}
    	
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${message_id:+-d message_id="$message_id"} \
									${inline_message_id:+-d inline_message_id="$inline_message_id"} \
    								${reply_markup:+-d reply_markup="$reply_markup"})
    
    	# Test the method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	return $?
	}

	TeleBot.setChatStickerSet()
	{
		local chat_id sticker_set_name jq_obj

		local param=$(getopt --name "$FUNCNAME" \
								--options 'c:s:' \
								--longoptions 'chat_id:,
												sticker_set_name:' \
								-- "$@")
		
		eval set -- "$param"
		
		while :
		do
			case $1 in
				-c|--chat_id)
					chat_id=$2
					shift 2
					;;
				-s|--sticker_set_name)
					sticker_set_name=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		[[ $chat_id ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
		[[ $sticker_set_name ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --sticker_set_name]"
		
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${sticker_set_name:+-d sticker_set_name="$sticker_set_name"})
		
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
		return $?
	}

	TeleBot.deleteChatStickerSet()
	{
		local chat_id jq_obj

		local param=$(getopt --name "$FUNCNAME" \
								--options 'c:' \
								--longoptions 'chat_id:' \
								-- "$@")
		
		eval set -- "$param"
		
		while :
		do
			case $1 in
				-c|--chat_id)
					chat_id=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
		
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} ${chat_id:+-d chat_id="$chat_id"})
		
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	
    	return $?
	}
	
	TeleBot.inputMedia()
	{
		local __type __input __media __caption __parse_mode __thumb __width 
		local __height __duration __supports_streaming __performer __title

		local __param=$(getopt --name "$FUNCNAME" \
								--options 't:i:m:c:p:b:w:h:d:s:f:e:' \
								--longoptions 'type:,
												input:,
												media:,
												caption:,
												parse_mode:,
												thumb:,
												witdh:,
												height:,
												duration:,
												supports_streaming:,
												performer:,
												title:' \
								-- "$@")
	
	
		eval set -- "$__param"
		
		while :
		do
			case $1 in
				-t|--type)
					__type=$2
					shift 2
					;;
				-i|--input)
					CheckArgType var "$1" "$2"
					__input=$2
					shift 2
					;;
				-m|--media)
					CheckArgType file "$1" "$2"
					__media=$2
					shift 2
					;;
				-c|--caption)
					__caption=$(echo -e "$2")
					shift 2
					;;
				-p|--parse_mode)
					__parse_mode=$2
					shift 2
					;;
				-b|--thumb)
					CheckArgType file "$1" "$2"
					__thumb=$2
					shift 2
					;;
				-w|--width)
					CheckArgType int "$1" "$2"
					__width=$2
					shift 2
					;;
				-h|--height)
					CheckArgType int "$1" "$2"
					__height=$2
					shift 2
					;;
				-d|--duration)
					CheckArgType int "$1" "$2"
					__duration=$2
					shift 2
					;;
				-s|--supports_streaming)
					CheckArgType bool "$1" "$2"
					__supports_streaming=$2
					shift 2
					;;
				-f|--performer)
					__performer=$2
					shift 2
					;;
				-e|--title)
					__title=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		[[ $__type ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --type]"
		[[ $__input ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-i, --input]"
		[[ $__media ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --media]"

		local -n __input=$__input
		
    	__input=${__input:+$__input,}{\"type\":\"$__type\",
		__input+=\"media\":\"$__media\"
		__input+=${__caption:+,\"caption\":\"$__caption\"}
		__input+=${__parse_mode:+,\"parse_mode\":\"$__parse_mode\"}
		__input+=${__thumb:+,\"thumb\":\"$__thumb\"}
		__input+=${__width:+,\"width\":$__width}
		__input+=${__height:+,\"height\":$__height}
		__input+=${__duration:+,\"duration\":$__duration}
		__input+=${__supports_streaming:+,\"supports_streaming\":$__supports_streaming}
		__input+=${__performer:+,\"performer\":\"$__performer\"}
		__input+=${__title:+,\"title\":\"$__title\"}}

		return $?
	}

	TeleBot.sendMediaGroup()
	{
		local chat_id media disable_notification reply_to_message_id jq_obj
		
		local param=$(getopt 	--name "$FUNCNAME" \
								--options 'c:m:n:r:' \
								--longoptions 'chat_id:,
												media:,
												disable_notification:,
												reply_to_message_id:' \
								-- "$@")
	
		eval set -- "$param"
		
		while :
		do
			case $1 in
				-c|--chat_id)
					chat_id=$2
					shift 2
					;;
				-m|--media)
					media=[$2]
					shift 2
					;;
				-n|--disable_notification)
    				CheckArgType bool "$1" "$2"
					disable_notification=$2
					shift 2
					;;
				-r|--reply_to_message_id)
    				CheckArgType int "$1" "$2"
    				reply_to_message_id=$2
    				shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		[[ $chat_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
		[[ $media ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --media]"
		
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
    								${media:+-F media="$media"} \
    								${disable_notification:+-F disable_notification="$disable_notification"} \
    								${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"})
    
		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
	}

	TeleBot.editMessageMedia()
	{
		local chat_id message_id inline_message_id media reply_markup jq_obj

		local param=$(getopt	--name "$FUNCNAME" \
								--options 'c:i:n:m:k:' \
								--longoptions	'chat_id:,
												message_id:,
												inline_message_id:,
												media:,
												reply_markup:'	\
								-- "$@")

		eval set -- "$param"
		
		while :
		do
			case $1 in
				-c|--chat_id)
					chat_id=$2
					shift 2
					;;
				-i|--message_id)
					CheckArgType int "$1" "$2"
					message_id=$2
					shift 2
					;;
				-n|--inline_message_id)
					CheckArgType int "$1" "$2"
					inline_message_id=$2
					shift 2
					;;
				-m|--media)
					media=$2
					shift 2
					;;
				-k|--reply_markup)
					reply_markup=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		[[ $inline_message_id ]] || {
			[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
			[[ $message_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-i, --message_id]"
		}
		
		[[ $media ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-m, --media]"
		
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${message_id:+-F message_id="$message_id"} \
									${inline_message_id:+-F inline_message_id="$inline_message_id"} \
    								${media:+-F media="$media"} \
    								${reply_markup:+-F reply_markup="$reply_markup"})   
		 
		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
	}

	TeleBot.sendAnimation()
	{
		local chat_id animation duration width height 
		local thumb caption parse_mode disable_notification 
		local reply_to_message_id reply_markup jq_obj
		
		local param=$(getopt	--name "$FUNCNAME" \
								--options 'c:a:d:w:h:b:o:p:n:r:k:' \
								--longoptions 'chat_id:,
												animation:,
												duration:,
												width:,
												height:,
												thumb:,
												caption:,
												parse_mode:,
												disable_notification:,
												reply_to_message_id:,
												reply_markup:' \
								-- "$@")
		
		eval set -- "$param"
		
		while :
		do
			case $1 in
				-c|--chat_id)
					chat_id=$2
					shift 2
					;;
				-a|--animation)
					CheckArgType file "$1" "$2"
					animation=$2
					shift 2
					;;
				-d|--duration)
					CheckArgType int "$1" "$2"
					duartion=$2
					shift 2
					;;
				-w|--width)
					CheckArgType int "$1" "$2"
					width=$2
					shift 2
					;;
				-h|--height)
					CheckArgType int "$1" "$2"
					height=$2
					shift 2
					;;
				-b|--thumb)
					CheckArgType file "$1" "$2"
					thumb=$2
					shift 2
					;;
				-o|--caption)
					caption=$(echo -e "$2")
					shift 2
					;;
				-p|--parse_mode)
					parse_mode=$2
					shift 2
					;;
				-n|--disable_notification)
					CheckArgType bool "$1" "$2"
					disable_notification=$2
					shift 2
					;;
				-r|--reply_to_message_id)
					CheckArgType int "$1" "$2"
					reply_to_message_id=$2
					shift 2
					;;
				-k|--reply_markup)
					reply_markup=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac
		done

		[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
		[[ $animation ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-a, --animation]"
		
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-F chat_id="$chat_id"} \
									${animation:+-F animation="$animation"} \
									${duration:+-F duration="$duration"} \
									${width:+-F width="$width"} \
									${height:+-F height="$height"} \
									${thumb:+-F thumb="$thumb"} \
									${caption:+-F caption="$caption"} \
									${parse_mode:+-F parse_mode="$parse_mode"} \
									${disable_notification:+-F disable_notification="$disable_notification"} \
									${reply_to_message_id:+-F reply_to_message_id="$reply_to_message_id"} \
    								${reply_markup:+-F reply_markup="$reply_markup"})   
		 
		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
	}
	
	TeleBot.answerInlineQuery()
	{
		local inline_query_id results cache_time is_personal
		local next_offset switch_pm_text switch_pm_parameter
		local jq_obj

		local param=$(getopt	--name "$FUNCNAME" \
								--options 'i:r:c:p:o:s:m:' \
								--longoptions 'inline_query_id:,
												results:,
												cache_time:,
												is_personal:,
												next_offset:,
												switch_pm_text:,
												switch_pm_parameter:' \
								-- "$@")

		eval set -- "$param"
		
		while :
		do
			case $1 in
				-i|--inline_query_id)		inline_query_id=$2;		shift 2;;
				-r|--results)				results=[$2];			shift 2;;
				-c|--cache_time)			cache_time=$2;			shift 2;;
				-p|--is_personal)			cache_time=$2;			shift 2;;
				-o|--next_offset)			next_offset=$2;			shift 2;;
				-s|--switch_pm_text)		switch_pm_text=$2;		shift 2;;
				-m|--switch_pm_parameter)	switch_pm_parameter=$2;	shift 2;;
				--)													shift; break;;
			esac
		done
		
		[[ $inline_query_id ]] 	|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-i, --inline_query_id]"
		[[ $results ]] 			|| MessageError API "$_ERR_PARAM_REQUIRED_" "[-r, --results]"

		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${inline_query_id:+-F inline_query_id="$inline_query_id"} \
									${results:+-F results="$results"} \
									${cache_time:+-F cache_time="$cache_time"} \
									${is_personal:+-F is_personal="$is_personal"} \
									${next_offset:+-F next_offset="$next_offset"} \
									${switch_pm_text:+-F switch_pm_text="$switch_pm_text"} \
									${switch_pm_parameter:+-F switch_pm_parameter="$switch_pm_parameter"})
		
		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
		
	}
	
	TeleBot.InlineQueryResult()
	{
		local __input __type __title __caption __reply_markup __parse_mode
		local __description __input_message_content __address __audio_duration
	   	local __audio_file_id __audio_url __document_file_id __document_url
		local __first_name __foursquare_id __foursquare_type __gif_duration
		local __gif_file_id __gif_height __gif_url __gif_width __hide_url
		local __last_name __latitude __live_period __longitude __mime_type
		local __mpeg4_duration __mpeg4_file_id __mpeg4_height __mpeg4_url
		local __mpeg4_width __performer __photo_file_id __photo_height 
		local __photo_url __photo_width __sticker_file_id __vcard __phone_number
		local __thumb_height __thumb_url __thumb_width __url __id
		local __video_duration __video_file_id __video_height __video_url
		local __video_width __voice_duration __voice_file_id __voice_url

		local __param=$(getopt	--name "$FUNCNAME" \
								--options 'i:t:l:c:k:p:r:d:m:b:s:x:w:v:z:y:q:a:f:u:g:o:n:h:j:e:
											N:R:D:A:X:G:C:Q:L:Y:E:V:H:Z:T:F:U:M:S:O:I:K:B:P:J:W:' \
								--longoptions 'input:,
												type:,
												title:,
												caption:,
												reply_markup:,
												parse_mode:,
												id:,
												description:,
												input_message_content:,
												address:,
												audio_duration:,
												audio_file_id:,
												audio_url:,
												document_file_id:,
												document_url:,
												first_name:,
												foursquare_id:,
												foursquare_type:,
												gif_duration:,
												gif_file_id:,
												gif_height:,
												gif_url:,
												gif_width:,
												hide_url:,
												last_name:,
												latitude:,
												live_period:,
												longitude:,
												mime_type:,
												mpeg4_duration:,
												mpeg4_file_id:,
												mpeg4_height:,
												mpeg4_url:,
												mpeg4_width:,
												performer:,
												photo_file_id:,
												photo_height:,
												photo_url:,
												photo_width:,
												sticker_file_id:,
												thumb_height:,
												thumb_url:,
												thumb_width:,
												url:,
												vcard:,
												video_duration:,
												video_file_id:,
												video_height:,
												video_url:,
												video_width:,
												voice_duration:,
												voice_file_id:,
												voice_url:,
												phone_number:' \
								-- "$@")

		eval set -- "$__param"

		while :
		do
			case $1 in
				-i|--input) 				CheckArgType var "$1" "$2"
					   						__input=$2; 				shift 2;;
				-t|--type)					__type=$2; 					shift 2;;
				-l|--title)					__title=$2;					shift 2;;
				-c|--caption)				__caption=$2;				shift 2;;
				-k|--reply_markup)			__reply_markup=$2;			shift 2;;
				-p|--parse_mode)			__parse_mode=$2;			shift 2;;
				-r|--id)					__id=$2;					shift 2;;
				-d|--description)			__description=$2;			shift 2;;
				-m|--input_message_content)	__input_message_content=$2;	shift 2;;
				-b|--address)				__address=$2;				shift 2;;
				-s|--audio_duration)		__audio_duration=$2;		shift 2;;
				-x|--audio_file_id)			__audio_file_id=$2;			shift 2;;
				-w|--audio_url)				__audio_url=$2;				shift 2;;
				-v|--document_file_id)		__document_file_id=$2;		shift 2;;
				-z|--document_url)			__document_url=$2;			shift 2;;
				-y|--first_name)			__first_name=$2;			shift 2;;
				-q|--foursquare_id)			__foursquare_id=$2;			shift 2;;
				-a|--foursquare_type)		__foursquare_type=$2;		shift 2;;
				-f|--gif_duration)			__gif_duration=$2;			shift 2;;
				-u|--gif_file_id)			__gif_file_id=$2			shift 2;;
				-g|--gif_height)			__gif_height=$2;			shift 2;;
				-o|--gif_url)				__gif_url=$2;				shift 2;;
				-n|--gif_width)				__gif_width=$2;				shift 2;;
				-h|--hide_url)				__hide_url=$2;				shift 2;;
				-j|--last_name)				__last_name=$2;				shift 2;;
				-e|--latitude)				__latitude=$2;				shift 2;;
				-N|--live_period)			__live_period=$2;			shift 2;;
				-R|--longitude)				__longitude=$2;				shift 2;;
				-D|--mime_type)				__mime_type=$2;				shift 2;;
				-A|--mpeg4_duration)		__mpeg4_duration=$2;		shift 2;;
				-X|--mpeg4_file_id)			__mpeg4_file_id=$2;			shift 2;;
				-G|--mpeg4_height)			__mpeg4_height=$2;			shift 2;;
				-C|--mpeg4_url)				__mpeg4_url=$2;				shift 2;;
				-Q|--mpeg4_width)			__mpeg4_width=$2;			shift 2;;
				-L|--performer)				__performer=$2;				shift 2;;
				-Y|--photo_file_id)			__photo_file_id=$2;			shift 2;;
				-E|--photo_height)			__photo_height=$2;			shift 2;;
				-V|--photo_url)				__photo_url=$2;				shift 2;;
				-H|--photo_width)			__photo_width=$2;			shift 2;;
				-Z|--sticker_file_id)		__sticker_file_id=$2;		shift 2;;
				-T|--thumb_height)			__thumb_height=$2;			shift 2;;
				-F|--thumb_url)				__thumb_url=$2;				shift 2;;
				-U|--thumb_width)			__thumb_width=$2;			shift 2;;
				-M|--url)					__url=$2;					shift 2;;
				-S|--vcard)					__vcard=$2;					shift 2;;
				-O|--video_duration)		__video_duration=$2;		shift 2;;
				-I|--video_file_id)			__video_file_id=$2;			shift 2;;
				-K|--video_height)			__video_height=$2;			shift 2;;
				-B|--video_url)				__video_url=$2;				shift 2;;
				-P|--video_width)			__video_width=$2;			shift 2;;
				-J|--voice_duration)		__voice_duration=$2;		shift 2;;
				-W|--voice_file_id)			__voice_file_id=$2;			shift 2;;
				--phone_number)				__phone_number=$2;			shift 2;;
				--voice_url)				__voice_url=$2;				shift 2;;
				--)														shift; break;;
			esac
		done

		[[ $__input ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-i, --input]"

		local -n __input=$__input

    	__input=${__input:+$__input,}{\"type\":\"$__type\"
		__input+=${__title:+,\"title\":\"$__title\"}
		__input+=${__caption:+,\"caption\":\"$__caption\"}
		__input+=${__reply_markup:+,\"reply_markup\":\"$__reply_markup\"}
		__input+=${__parse_mode:+,\"parse_mode\":\"$__parse_mode\"}
		__input+=${__id:+,\"id\":\"$__id\"}
		__input+=${__description:+,\"description\":\"$__description\"}
		__input+=${__input_message_content:+,\"input_message_content\":$__input_message_content}
		__input+=${__address:+,\"address\":\"$__address\"}
		__input+=${__audio_duration:+,\"audio_duration\":$__audio_duration}
		__input+=${__audio_file_id:+,\"audio_file_id\":\"$__audio_file_id\"}
		__input+=${__audio_url:+,\"audio_url\":\"$__audio_url\"}
		__input+=${__document_file_id:+,\"document_file_id\":\"$__document_file_id\"}
		__input+=${__document_url:+,\"document_url\":\"$__document_url\"}
		__input+=${__first_name:+,\"first_name\":\"$__first_name\"}
		__input+=${__foursquare_id:+,\"foursquare_id\":\"$__foursquare_id\"}
		__input+=${__foursquare_type:+,\"foursquare_type\":\"$__foursquare_type\"}
		__input+=${__gif_duration:+,\"gif_duration\":$__gif_duration}
		__input+=${__gif_file_id:+,\"gif_file_id\":\"$__gif_file_id\"}
		__input+=${__gif_height:+,\"gif_height\":$__gif_height}
		__input+=${__gif_url:+,\"gif_url\":\"$__gif_url\"}
		__input+=${__gif_width:+,\"gif_width\":$__gif_width}
		__input+=${__hide_url:+,\"hide_url\":\"$__hide_url\"}
		__input+=${__last_name:+,\"last_name\":\"$__last_name\"}
		__input+=${__latitude:+,\"latitude\":$__latitude}
		__input+=${__live_period:+,\"live_period\":$__live_period}
		__input+=${__longitude:+,\"longitude\":$__longitude}
		__input+=${__mime_type:+,\"mime_type\":\"$__mime_type\"}
		__input+=${__mpeg4_duration:+,\"mpeg4_duration\":$__mpeg4_duration}
		__input+=${__mpeg4_file_id:+,\"mpeg4_file_id\":\"$__mpeg4_file_id\"}
		__input+=${__mpeg4_height:+,\"mpeg4_height\":$__mpeg4_height}
		__input+=${__mpeg4_url:+,\"mpeg4_url\":\"$__mpeg4_url\"}
		__input+=${__mpeg4_width:+,\"mpeg4_width\":$__mpeg4_width}
		__input+=${__performer:+,\"performer\":\"$__performer\"}
		__input+=${__photo_file_id:+,\"photo_file_id\":\"$__photo_file_id\"}
		__input+=${__photo_height:+,\"photo_height\":$__photo_height}
		__input+=${__photo_url:+,\"photo_url\":\"$__photo_url\"}
		__input+=${__photo_width:+,\"photo_width\":$__photo_width}
		__input+=${__sticker_file_id:+,\"sticker_file_id\":\"$__sticker_file_id\"}
		__input+=${__thumb_height:+,\"thumb_height\":$__thumb_height}
		__input+=${__thumb_url:+,\"thumb_url\":\"$__thumb_url\"}
		__input+=${__thumb_width:+,\"thumb_width\":$__thumb_width}
		__input+=${__url:+,\"url\":\"$__url\"}
		__input+=${__vcard:+,\"vcard\":\"$__vcard\"}
		__input+=${__video_duration:+,\"video_duration\":$__video_duration}
		__input+=${__video_file_id:+,\"video_file_id\":\"$__video_file_id\"}
		__input+=${__video_height:+,\"video_height\":$__video_height}
		__input+=${__video_url:+,\"video_url\":\"$__video_url\"}
		__input+=${__video_width:+,\"video_width\":$__video_width}
		__input+=${__voice_duration:+,\"voice_duration\":$__voice_duration}
		__input+=${__voice_file_id:+,\"voice_file_id\":\"$__voice_file_id\"}
		__input+=${__voice_url:+,\"voice_url\":\"$__voice_url\"}
		__input+=${__phone_number:+,\"phone_number\":\"$__phone_number\"}}

		return $?
	}

	TeleBot.InputMessageContent()
	{
		local message_text parse_mode disable_web_page_preview json
		local latitude longitude live_period title address foursquare_id
		local foursquare_type phone_number first_name last_name vcard

		local param=$(getopt	--name "$FUNCNAME" \
								--options 't:p:w:l:v:e:a:f:q:n:m:s:d:' \
								--longoptions 'message_text:,
												parse_mode:,
												disable_web_page_preview:,
												latitude:,
												longitude:,
												live_period:,
												title:,
												address:,
												foursquare_id:,
												foursquare_type:,
												phone_number:,
												first_name:,
												last_name:,
												vcard:' \
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-t|--message_text) 				message_text=$(echo -e "$2");	shift 2;;
				-p|--parse_mode)				parse_mode=$2; 					shift 2;;
				-w|--disable_web_page_preview)	disable_web_page_preview=$2; 	shift 2;;
				-l|--latitude)					latitude=$2;					shift 2;;
				-g|--longitude)					longitude=$2;					shift 2;;
				-v|--live_period)				live_period=$2;					shift 2;;
				-e|--title)						title=$2;						shift 2;;
				-a|--address)					address=$2;						shift 2;;
				-f|--foursquare_id)				foursquare_id=$2;				shift 2;;
				-q|--foursquare_type)			foursquare_type=$2;				shift 2;;
				-n|--phone_number)				phone_number=$2;				shift 2;;
				-m|--first_name)				first_name=$2;					shift 2;;
				-s|--last_name)					last_name=$2;					shift 2;;
				-d|--vcard)						vcard=$2;						shift 2;;
				--) 															shift; break;;
			esac
		done
		
		json=${message_text:+\"message_text\":\"$message_text\"}
		json+=${parse_mode:+,\"parse_mode\":\"$parse_mode\"}
		json+=${disable_web_page_preview:+,\"disable_web_page_preview\":$disable_web_page_preview}
		json+=${latitude:+,\"latitude\":$latitude}
		json+=${longitude:+,\"longtitude\":$longitude}
		json+=${live_period:+,\"live_period\":$live_period}
		json+=${title:+,\"title\":\"$title\"}
		json+=${address:+,\"address\":\"$address\"}
		json+=${foursquare_id:+,\"foursquare_id\":\"$foursquare_id\"}
		json+=${foursquare_type:+,\"foursquare_type\":\"$foursquare_type\"}
		json+=${phone_number:+,\"phone_number\":\"$phone_number\"}
		json+=${first_name:+,\"first_name\":\"$first_name\"}
		json+=${last_name:+,\"last_name\":\"$last_name\"}
		json+=${vcard:+,\"vcard\":\"$vcard\"}
		
		echo "{${json#,}}"

		return $?
	}

	TeleBot.ChatPermissions()
	{
		local can_send_messages can_send_media_messages can_send_polls
		local can_send_other_messages can_add_web_page_previews json
		local can_change_info can_invite_users can_pin_messages

		local param=$(getopt	--name "$FUNCNAME" \
								--options 'm:d:l:o:w:c:i:p:' \
								--longoptions 'can_send_messages:,
												can_send_media_messages:,
												can_send_polls:,
												can_send_other_messages:,
												can_add_web_page_previews:,
												can_change_info:,
												can_invite_users:,
												can_pin_messages:' \
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-m|--can_send_messages) 		can_send_messages=$2;;
				-d|--can_send_media_messages) 	can_send_media_messages=$2;;
				-l|--can_send_polls)			can_send_polls=$2;;
				-o|--can_send_other_messages)	can_send_other_messages=$2;;
				-w|--can_add_web_page_previews) can_add_web_page_previews=$2;;
				-c|--can_change_info)			can_change_info=$2;;
				-i|--can_invite_users)			can_invite_users=$2;;
				-p|--can_pin_messages)			can_pin_messages=$2;;
				--) shift; break;;
			esac
			shift 2
		done
		
		json=${can_send_messages:+\"can_send_messages\":$can_send_messages,}
		json+=${can_send_media_messages:+\"can_send_media_messages\":$can_send_media_messages,}
		json+=${can_send_polls:+\"can_send_polls\":$can_send_polls,}
		json+=${can_send_other_messages:+\"can_send_other_messages\":$can_send_other_messages,}
		json+=${can_add_web_page_previews:+\"can_add_web_page_previews\":$can_add_web_page_previews,}
		json+=${can_change_info:+\"can_change_info\":$can_change_info,}
		json+=${can_invite_users:+\"can_invite_users\":$can_invite_users,}
		json+=${can_pin_messages:+\"can_pin_messages\":$can_pin_messages,}
	
		# Retorna o objeto de permissões.
		echo "{${json%,}}"

    	# Status
    	return $?
	}

	TeleBot.setChatPermissions()
	{
		local chat_id permissions jq_obj

		local param=$(getopt	--name "$FUNCNAME" \
								--options 'c:p:' \
								--longoptions 'chat_id:,permissions:' \
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-c|--chat_id) 		chat_id=$2;;
				-p|--permissions)	permissions=$2;;
				--) shift; break;;
			esac
			shift 2
		done
		
		[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
		[[ $permissions ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-p, --permissions]"

		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${permissions:+-d permissions="$permissions"})
		
		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?

	}
	
	TeleBot.setChatAdministratorCustomTitle()
	{
		local chat_id user_id custom_title jq_obj

		local param=$(getopt	--name "$FUNCNAME" \
								--options 'c:u:t:' \
								--longoptions 'chat_id:,
												user_id:,
												custom_title:' \
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-c|--chat_id) 		chat_id=$2;;
				-u|--user_id) 		user_id=$2;;
				-t|--custom_title) 	custom_title=$2;;
				--) shift; break;;
			esac
			shift 2
		done
		
		[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
		[[ $user_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --user_id]"
		[[ $custom_title ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --custom_title]"

		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${user_id:+-d user_id="$user_id"} \
									${custom_tilte:+-d custom_title="$custom_title"})
		
		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
	}

	TeleBot.sendPoll()
	{
		local chat_id question options is_anonymous reply_markup
		local type allows_multiple_answers correct_option_id jq_obj
		local is_closed disable_notification reply_to_message_id
		local explanation explanation_parse_mode open_period close_date

		local param=$(getopt	--name "$FUNCNAME" \
								--options 'c:q:o:a:k:t:m:i:x:z:p:d:l:n:r:' \
								--longoptions 'chat_id:,
												question:,
												options:,
												is_anonymous:,
												reply_markup:,
												type:,
												allows_multiple_answers:,
												correct_option_id:,
												explanation:,
												explanation_parse_mode:,
												open_period:,
												close_date:,
												is_closed:,
												disable_notification:,
												reply_to_message_id:' \
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-c|--chat_id) chat_id=$2;;
				-q|--question) question=$(echo -e "$2");;
				-o|--options) options=$(echo -e "$2");;
				-a|--is_anonymous) is_anonymous=$2;;
				-k|--reply_markup) reply_markup=$2;;
				-t|--type) type=$2;;
				-m|--allows_multiple_answers) allows_multiple_answers=$2;;
				-i|--correct_option_id) correct_option_id=$2;;
				-x|--explanation) explanation=$2;;
				-z|--explanation_parse_mode) explanation_parse_mode=$2;;
				-p|--open_period) open_period=$2;;
				-d|--close_date) close_date=$2;;
				-l|--is_closed) is_closed=$2;;
				-n|--disable_notification) disable_notification=$2;;
				-r|--reply_to_message_id) reply_to_message_id=$2;;
				--) shift; break;;
			esac
			shift 2
		done
		
		[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"
		[[ $question ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-q, --question]"
		[[ $options ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-o, --options]"

		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${question:+-d question="$question"} \
									${options:+-d options="$options"} \
									${is_anonymous:+-d is_anonymous="$is_anonymous"} \
									${reply_markup:+-d reply_markup="$reply_markup"} \
									${type:+-d type="$type"} \
									${allows_multiple_answers:+-d allows_multiple_answers="$allows_multiple_answers"} \
									${correct_option_id:+-d correct_option_id="$correct_option_id"} \
									${explanation:+-d explanation="$explanation"} \
									${explanation_parse_mode:+-d explanation_parse_mode="$explanation_parse_mode"} \
									${open_period:+-d open_period="$open_period"} \
									${close_date:+-d close_date="$close_date"} \
									${is_closed:+-d is_closed="$is_closed"} \
									${disable_notification:+-d disable_notification="$disable_notification"} \
									${reply_to_message_id:+-d reply_to_message_id="$reply_to_message_id"})
		
		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?

	}

	TeleBot.KeyboardButtonPollType()
	{
		local type

		local param=$(getopt --name "$FUNCNAME" --options 't:' --longoptions 'type:' -- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-t|--type) type=$2;;
				--) shift; break;;
			esac
			shift 2
		done

		[[ $type ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-t, --type]"

		printf '{"type": "%s"}' "$type"

		return 0
	}
	
	TeleBot.sendDice()
	{
		local chat_id disable_notification reply_to_message_id 
		local reply_markup jq_obj emoji

		local param=$(getopt 	--name "$FUNCNAME" \
								--options 'c:e:n:r:k:' \
								--longoptions 'chat_id:,
												emoji:,
												disable_notification:,
												reply_to_message_id:,
												reply_markup:' \
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-c|--chat_id) chat_id=$2;;
				-e|--emoji) emoji=$2;;
				-n|--disable_notification) disable_notification=$2;;
				-r|--reply_to_message_id) reply_to_message_id=$2;;
				-k|--reply_markup) reply_markup=$2;;
				--) shift; break;;
			esac
			shift 2
		done
		
		[[ $chat_id ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --chat_id]"

		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
									${chat_id:+-d chat_id="$chat_id"} \
									${emoji:+-d emoji="$emoji"} \
									${disable_notification:+-d disable_notification="$disable_notification"} \
									${reply_to_message_id:+-d reply_to_message_id="$reply_to_message_id"} \
									${reply_markup:+-d reply_markup="$reply_markup"})

		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
	}

	TeleBot.getMyCommands()
	{
		local jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.})
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    	return $?
	}

	TeleBot.setMyCommands()
	{
		local jq_obj commands

		local param=$(getopt 	--name "$FUNCNAME" \
								--options 'c:' \
								--longoptions 'commands:' \
								-- "$@")

		eval set -- "$param"

		while :
		do
			case $1 in
				-c|--commands) commands=$2;;
				--) break;;	
			esac
			shift 2
		done
		
		[[ $commands ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --commands]"

		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} ${commands:+-d commands="$commands"})

		# Method return
    	MethodReturn "$jq_obj" || MessageError TG "$jq_obj"
    
    	# Status
    	return $?
	}

	TeleBot.BotCommand()
	{
		local __command __description __list
		
		local __param=$(getopt 	--name "$FUNCNAME" \
								--options 'l:c:d:' \
								--longoptions 'list:,
												command:,
												description:' \
								-- "$@")

		eval set -- "$__param"

		while :
		do
			case $1 in
				-l|--list) 	CheckArgType var "$1" "$2"; __list=$2;;
				-c|--command) __command=$2;;
				-d|--description) __description=$2;;
				--) break;;
			esac
			shift 2
		done

		[[ $__list ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-l, --list]"
		[[ $__command ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-c, --command]"
		[[ $__description ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-d, --description]"

		printf -v $__list '%s' "${!__list#[}"
		printf -v $__list '%s' "${!__list%]}"
		
		printf -v $__list '%s{"command": "%s", "description": "%s"}' 	\
							"${!__list:+${!__list},}"					\
							"$__command"								\
							"$__description"

		printf -v $__list '%s' "[${!__list}]"

		return $?
	}

	TeleBot.setMessageRules()
	{
		local action command user_id username chat_id 
		local chat_type time date language message_id 
		local is_bot text entities_type file_type name
		local query_data query_id query_text send_message
		local chat_member mime_type num_args exec rule
		local action_args weekday user_status chat_name 
		local message_status reply_message parse_mode
		local forward_message reply_markup continue i
		local author_signature bot_action auth_file

		local param=$(getopt	--name "$FUNCNAME" \
								--options 's:a:z:c:i:u:h:v:y:l:m:b:t:n:f:p:q:r:g:o:e:d:w:j:x:R:S:F:K:P:E:A:C:B:T:' \
								--longoptions	'name:,
												action:,
												action_args:,
												command:,
												user_id:,
												username:,
												chat_id:,
												chat_name:,
												chat_type:,
												language_code:,
												message_id:,
												is_bot:,
												text:,
												entitie_type:,
												file_type:,
												mime_type:,
												query_data:,
												query_id:,
												chat_member:,
												num_args:,
												time:,
												date:,
												weekday:,
												user_status:,
												message_status:,
												exec:,
												auth_file:,
												bot_reply_message:,
												bot_send_message:,
												bot_forward_message:,
												bot_reply_markup:,
												bot_parse_mode:,
												bot_action:,
												author_signature:,
												continue' \
								-- "$@")
		
		eval set -- "$param"
	
		while :
		do
			case $1 in
				-s|--name)
					CheckArgType flag "$1" "$2"
					name=$2
					shift 2
					;;
				-a|--action)
					CheckArgType func "$1" "$2"
					action=$2
					shift 2
					;;
				-z|--action_args)
					action_args=$2
					shift 2
					;;
				-c|--command)
					CheckArgType cmd "$1" "$2"
					command=$2
					shift 2
					;;
				-i|--user_id)
					user_id=${user_id:+$user_id|}${2//[,$'\n']/|}
					shift 2
					;;
				-u|--username)
					username=${username:+$username|}${2//[,$'\n']/|}
					shift 2
					;;
				-h|--chat_id)
					chat_id=${chat_id:+$chat_id|}${2//[,$'\n']/|}
					shift 2
					;;
				-v|--chat_name)
					chat_name=${chat_name:+$chat_name|}${2//[,$'\n']/|}
					shift 2
					;;
				-y|--chat_type)
					chat_type=${chat_type:+$chat_type|}${2//[,$'\n']/|}
					shift 2
					;;
				-e|--time)
					time=${time:+$time|}${2//[,$'\n']/|}
					shift 2
					;;
				-d|--date)
					date=${date:+$date|}${2//[,$'\n']/|}
					shift 2
					;;
				-l|--laguage_code)
					language=${language:+$language|}${2//[,$'\n']/|}
					shift 2
					;;
				-m|--message_id)
					message_id=${message_id:+$message_id|}${2//[,$'\n']/|}
					shift 2
					;;
				-b|--is_bot)
					is_bot=${is_bot:+$is_bot|}${2//[,$'\n']/|}
					shift 2
					;;
				-t|--text)
					text=${2//$'\n'/|}
					shift 2
					;;
				-n|--entitie_type)
					entities_type=${entities_type:+$entities_type|}${2//[,$'\n']/|}
					shift 2
					;;
				-f|--file_type)
					file_type=${file_type:+$file_type|}${2//[,$'\n']/|}
					shift 2
					;;
				-p|--mime_type)
					mime_type=${mime_type:+$mime_type|}${2//[,$'\n']/|}
					shift 2
					;;
				-q|--query_data)
					query_data=${query_data:+$query_data|}${2//[,$'\n']/|}
					shift 2
					;;
				-r|--query_id)
					query_id=${query_id:+$query_id|}${2//[,$'\n']/|}
					shift 2
					;;
				-g|--chat_member)
					chat_member=${chat_member:+$chat_member|}${2//[,$'\n']/|}
					shift 2
					;;
				-o|--num_args)
					num_args=${num_args:+$num_args|}${2//[,$'\n']/|}
					shift 2
					;;
				-w|--weekday)
					weekday=${weekday:+$weekday|}${2//[,$'\n']/|}
					shift 2
					;;
				-j|--user_status)
					user_status=${user_status:+$user_status|}${2//[,$'\n']/|}
					shift 2
					;;
				-x|--message_status)
					message_status=${message_status:+$message_status|}${2//[,$'\n']/|}
					shift 2
					;;
				-T|--auth_file)
					auth_file=${auth_file:+$auth_file|}${2//[,$'\n']/|}
					shift 2
					;;
				-R|--bot_reply_message)
					reply_message=$2
					shift 2
					;;
				-S|--bot_send_message)
					send_message=$2
					shift 2
					;;
				-F|--bot_forward_message)
					forward_message=${forward_message:+$forward_message|}${2//[,$'\n']/|}
					shift 2
					;;
				-K|--bot_reply_markup)
					reply_markup=$2
					shift 2
					;;
				-P|--bot_parse_mode)
					parse_mode=$2
					shift 2
					;;
				-B|--bot_action)
					bot_action=$2
					shift 2
					;;
				-E|--exec)
					exec=$2
					shift 2
					;;
				-A|--author_signature)
					author_signature=${author_signature:+$author_signature|}${2//[,$'\n']/|}
					shift 2
					;;
				-C|--continue)
					continue=true
					shift
					;;
				--)
					shift
					break
					;;
			esac
		done
		
		[[ $name ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-s, --name]"
		[[ ${_BOT_RULES_[$name]} ]] && MessageError API "$_ERR_RULE_ALREADY_EXISTS_" "[-s, --name]" "$name"

		i=${_BOT_RULES_INDEX_:=0}

		_BOT_RULES_[$i:source]=${BASH_SOURCE[1]##*/}
		_BOT_RULES_[$i:line]=${BASH_LINENO}
		_BOT_RULES_[$i:name]=${name}
		_BOT_RULES_[$i:action]=${action}
		_BOT_RULES_[$i:action_args]=${action_args}
		_BOT_RULES_[$i:user_id]=${user_id}
		_BOT_RULES_[$i:username]=${username}
		_BOT_RULES_[$i:chat_id]=${chat_id}
		_BOT_RULES_[$i:chat_name]=${chat_name}
		_BOT_RULES_[$i:chat_type]=${chat_type}
		_BOT_RULES_[$i:language_code]=${language}
		_BOT_RULES_[$i:message_id]=${message_id}
		_BOT_RULES_[$i:is_bot]=${is_bot}
		_BOT_RULES_[$i:command]=${command}
		_BOT_RULES_[$i:text]=${text}
		_BOT_RULES_[$i:entities_type]=${entities_type}
		_BOT_RULES_[$i:file_type]=${file_type}
		_BOT_RULES_[$i:mime_type]=${mime_type}
		_BOT_RULES_[$i:query_data]=${query_data}
		_BOT_RULES_[$i:query_id]=${query_id}
		_BOT_RULES_[$i:chat_member]=${chat_member}
		_BOT_RULES_[$i:num_args]=${num_args}
		_BOT_RULES_[$i:time]=${time}
		_BOT_RULES_[$i:date]=${date}
		_BOT_RULES_[$i:weekday]=${weekday}
		_BOT_RULES_[$i:user_status]=${user_status}
		_BOT_RULES_[$i:message_status]=${message_status}
		_BOT_RULES_[$i:author_signature]=${author_signature}
		_BOT_RULES_[$i:auth_file]=${auth_file}
		_BOT_RULES_[$i:bot_reply_message]=${reply_message}
		_BOT_RULES_[$i:bot_send_message]=${send_message}
		_BOT_RULES_[$i:bot_forward_message]=${forward_message}
		_BOT_RULES_[$i:bot_reply_markup]=${reply_markup}
		_BOT_RULES_[$i:bot_parse_mode]=${parse_mode}
		_BOT_RULES_[$i:bot_action]=${bot_action}
		_BOT_RULES_[$i:exec]=${exec}
		_BOT_RULES_[$i:continue]=${continue}
		_BOT_RULES_[$name]=true

		# Increase index.
		((_BOT_RULES_INDEX_++))

		return $?
	}
	
	TeleBot.manageRules()
	{
		local uid rule botcmd err tm stime etime ctime mime_type weekday
		local dt sdate edate cdate mem ent type args status out fwid
	   	local stdout i re match file user line

		local u_message_text u_message_id u_message_from_is_bot 
		local u_message_from_id u_message_from_username msgstatus argpos
		local u_message_from_language_code u_message_chat_id message_status
		local u_message_chat_type u_message_date u_message_entities_type
		local u_message_mime_type u_message_author_signature

		local 	param=$(getopt	--name "$FUNCNAME" \
									--options 'u:' \
									--longoptions 'update_id:' \
									-- "$@")

				
		eval set -- "$param"
		
		while :
		do
			case $1 in
				-u|--update_id)
					CheckArgType int "$1" "$2"
					uid=$2
					shift 2
					;;
				--)
					shift
					break
					;;
			esac			
		done
		
		[[ $uid ]] || MessageError API "$_ERR_PARAM_REQUIRED_" "[-u, --update_id]"

		# Rules (read-only)
		readonly _BOT_RULES_ _BOT_RULES_INDEX_
		
		[[ ${u_message_text:=${message_text[$uid]}} 				]] ||
		[[ ${u_message_text:=${edited_message_text[$uid]}} 			]] ||
		[[ ${u_message_text:=${callback_query_message_text[$uid]}}	]] ||
		[[ ${u_message_text:=${inline_query_query[$uid]}} 			]] ||
		[[ ${u_message_text:=${chosen_inline_result_query[$uid]}}	]] ||
		[[ ${u_message_text:=${channel_post_text[$uid]}}			]] ||
		[[ ${u_message_text:=${edited_channel_post_text[$uid]}}		]]

		[[ ${u_message_id:=${message_message_id[$uid]}}					]] ||
		[[ ${u_message_id:=${edited_message_message_id[$uid]}} 			]] ||
		[[ ${u_message_id:=${callback_query_message_message_id[$uid]}} 	]] ||
		[[ ${u_message_id:=${inline_query_id[$uid]}} 					]] ||
		[[ ${u_message_id:=${chosen_inline_result_result_id[$uid]}}		]] ||
		[[ ${u_message_id:=${channel_post_message_id[$uid]}}			]] ||
		[[ ${u_message_id:=${edited_channel_post_message_id[$uid]}}		]] ||
		[[ ${u_message_id:=${poll_answer_poll_id[$uid]}}				]]

		[[ ${u_message_from_is_bot:=${message_from_is_bot[$uid]}} 				]] ||
		[[ ${u_message_from_is_bot:=${edited_message_from_is_bot[$uid]}} 		]] ||
		[[ ${u_message_from_is_bot:=${callback_query_from_is_bot[$uid]}} 		]] ||
		[[ ${u_message_from_is_bot:=${inline_query_from_is_bot[$uid]}} 			]] ||
		[[ ${u_message_from_is_bot:=${chosen_inline_result_from_is_bot[$uid]}}	]] ||
		[[ ${u_message_from_is_bot:=${poll_answer_user_is_bot[$uid]}}			]]

		[[ ${u_message_from_id:=${message_from_id[$uid]}} 				]] ||
		[[ ${u_message_from_id:=${edited_message_from_id[$uid]}} 		]] ||
		[[ ${u_message_from_id:=${callback_query_from_id[$uid]}} 		]] ||
		[[ ${u_message_from_id:=${inline_query_from_id[$uid]}} 			]] ||
		[[ ${u_message_from_id:=${chosen_inline_result_from_id[$uid]}}	]] ||
		[[ ${u_message_from_id:=${poll_answer_user_id[$uid]}}			]]

		[[ ${u_message_from_username:=${message_from_username[$uid]}} 				]] ||
		[[ ${u_message_from_username:=${edited_message_from_username[$uid]}} 		]] ||
		[[ ${u_message_from_username:=${callback_query_from_username[$uid]}} 		]] ||
		[[ ${u_message_from_username:=${inline_query_from_username[$uid]}} 			]] ||
		[[ ${u_message_from_username:=${chosen_inline_result_from_username[$uid]}}	]] ||
		[[ ${u_message_from_username:=${poll_answer_user_username[$uid]}}			]]

		[[ ${u_message_from_language_code:=${message_from_language_code[$uid]}} 				]] ||
		[[ ${u_message_from_language_code:=${edited_message_from_language_code[$uid]}} 			]] ||
		[[ ${u_message_from_language_code:=${callback_query_from_language_code[$uid]}} 			]] ||
		[[ ${u_message_from_language_code:=${inline_query_from_language_code[$uid]}} 			]] ||
		[[ ${u_message_from_language_code:=${chosen_inline_result_from_language_code[$uid]}}	]]

		[[ ${u_message_chat_id:=${message_chat_id[$uid]}} 					]] ||
		[[ ${u_message_chat_id:=${edited_message_chat_id[$uid]}} 			]] ||
		[[ ${u_message_chat_id:=${callback_query_message_chat_id[$uid]}}	]] ||
		[[ ${u_message_chat_id:=${channel_post_chat_id[$uid]}}				]] ||
		[[ ${u_message_chat_id:=${edited_channel_post_chat_id[$uid]}}		]]

		[[ ${u_message_chat_username:=${message_chat_username[$uid]}}					]] ||
		[[ ${u_message_chat_username:=${edited_message_chat_username[$uid]}} 			]] ||
		[[ ${u_message_chat_username:=${callback_query_message_chat_username[$uid]}}	]]

		[[ ${u_message_chat_type:=${message_chat_type[$uid]}} 					]] ||
		[[ ${u_message_chat_type:=${edited_message_chat_type[$uid]}} 			]] ||
		[[ ${u_message_chat_type:=${callback_query_message_chat_type[$uid]}}	]] ||
		[[ ${u_message_chat_type:=${channel_post_chat_type[$uid]}}				]] ||
		[[ ${u_message_chat_type:=${edited_channel_post_chat_type[$uid]}}		]]

		[[ ${u_message_date:=${message_date[$uid]}} 				]] ||
		[[ ${u_message_date:=${edited_message_edit_date[$uid]}} 	]] ||
		[[ ${u_message_date:=${callback_query_message_date[$uid]}}	]] ||
		[[ ${u_message_date:=${channel_post_date[$uid]}}			]] ||
		[[ ${u_message_date:=${edited_channel_post_date[$uid]}}		]]

		[[ ${u_message_entities_type:=${message_entities_type[$uid]}} 					]] ||
		[[ ${u_message_entities_type:=${edited_message_entities_type[$uid]}} 			]] ||
		[[ ${u_message_entities_type:=${callback_query_message_entities_type[$uid]}}	]] ||
		[[ ${u_message_entities_type:=${channel_post_entities_type[$uid]}}				]] ||
		[[ ${u_message_entities_type:=${edited_channel_post_entities_type[$uid]}}		]]

		[[ ${u_message_mime_type:=${message_document_mime_type[$uid]}} 		]] ||
		[[ ${u_message_mime_type:=${message_video_mime_type[$uid]}} 		]] ||
		[[ ${u_message_mime_type:=${message_audio_mime_type[$uid]}} 		]] ||
		[[ ${u_message_mime_type:=${message_voice_mime_type[$uid]}}			]] ||
		[[ ${u_message_mime_type:=${channel_post_document_mime_type[$uid]}} ]]

		[[ ${u_message_author_signature:=${channel_post_author_signature[$uid]}} 		]] ||
		[[ ${u_message_author_signature:=${edited_channel_post_author_signature[$uid]}} ]]

		# Rules
		for ((i=0; i < _BOT_RULES_INDEX_; i++)); do
		
			IFS=' ' read -ra args <<< $u_message_text
			
			[[ ! ${_BOT_RULES_[$i:num_args]}			||	${#args[@]}							== @(${_BOT_RULES_[$i:num_args]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:command]}				||	${u_message_text%% *}				== @(${_BOT_RULES_[$i:command]})?(@${_BOT_INFO_[3]}) 	]]	&&
			[[ ! ${_BOT_RULES_[$i:message_id]} 			||	$u_message_id 						== @(${_BOT_RULES_[$i:message_id]})						]] 	&&
			[[ ! ${_BOT_RULES_[$i:is_bot]} 				||	$u_message_from_is_bot				== @(${_BOT_RULES_[$i:is_bot]})							]]	&&
			[[ ! ${_BOT_RULES_[$i:user_id]}				||	$u_message_from_id					== @(${_BOT_RULES_[$i:user_id]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:username]}			||	$u_message_from_username			== @(${_BOT_RULES_[$i:username]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:language]}			||	$u_message_from_language_code		== @(${_BOT_RULES_[$i:language]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:chat_id]}				||	$u_message_chat_id					== @(${_BOT_RULES_[$i:chat_id]})						]] 	&&
			[[ ! ${_BOT_RULES_[$i:chat_name]}			||	$u_message_chat_username			== @(${_BOT_RULES_[$i:chat_name]})						]] 	&&
			[[ ! ${_BOT_RULES_[$i:chat_type]}			||	$u_message_chat_type				== @(${_BOT_RULES_[$i:chat_type]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:author_signature]}	||	$u_message_author_signature			== @(${_BOT_RULES_[$i:author_signature]})				]]	&&
			[[ ! ${_BOT_RULES_[$i:mime_type]}			||	$u_message_mime_type				== @(${_BOT_RULES_[$i:mime_type]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:query_id]}			||	${callback_query_id[$uid]}			== @(${_BOT_RULES_[$i:query_id]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:query_data]}			||	${callback_query_data[$uid]}		== @(${_BOT_RULES_[$i:query_data]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:weekday]}				|| 	$(printf '%(%u)T' $u_message_date) 	== @(${_BOT_RULES_[$i:weekday]})						]]	&&
			[[ ! ${_BOT_RULES_[$i:text]}				||	$u_message_text						=~ ${_BOT_RULES_[$i:text]}								]]	|| continue

			# Extract the files from the denied set. in case you are absent
			# defines the default expression.
			# Capture the groups contained in the pattern, separating the
	   		# negation operator '!' (if present) to determine the
			# range validation handling.
			#
			# Example 1:
			#              
			#       BASH_REMATCH[2]
			#    __________|__________
			#   |                     |
			# !(12:00-13:00,15:00-17:00)
			# |
			# |_ BASH_REMATCH[1]
			#
			re='^(!)\(([^)]+)\)$'

			[[ ${_BOT_RULES_[$i:auth_file]} =~ $re ]]
			match=${BASH_REMATCH[2]:-${_BOT_RULES_[$i:auth_file]}}
			
			for file in ${match//|/ }; do
				# Test file access.
				if ! [[ -f "$file" && -r "$file" ]]; then
					MessageError API "'$file' $_ERR_FILE_NOT_FOUND_" "${_BOT_RULES_[$i:name]}" '[-T, --auth_file]'
				fi

				# Read users by removing additional comments
				# and ignores the line prefixed with hashtag '#'.
				while read -r line; do
					user=${line%%*( )#*}
					[[ $user != *( )#* ]] 													&&
					[[ $user == $u_message_from_id || $user == $u_message_from_username	]] 	&& break 2
				done < "$file"
			done

			((${BASH_REMATCH[1]} $?)) && continue
	
			for msgstatus in ${_BOT_RULES_[$i:message_status]//|/ }; do
				[[ $msgstatus == pinned		&& ${message_pinned_message_message_id[$uid]:-${channel_post_pinned_message_message_id[$uid]}} 		]] 	||
				[[ $msgstatus == edited 	&& ${edited_message_message_id[$uid]:-${edited_channel_post_message_id[$uid]}}						]] 	||
				[[ $msgstatus == forwarded	&& ${message_forward_from_id[$uid]:-${channel_post_forward_from_chat_id[$uid]}}						]]	||
				[[ $msgstatus == reply		&& ${message_reply_to_message_message_id[$uid]:-${channel_post_reply_to_message_message_id[$uid]}}	]] 	||
				[[ $msgstatus == callback	&& ${callback_query_message_message_id[$uid]}														]]	||
				[[ $msgstatus == inline		&& ${inline_query_id[$uid]}																			]]	||
				[[ $msgstatus == chosen		&& ${chosen_inline_result_result_id[$uid]}															]]	||
				[[ $msgstatus == poll		&& ${poll_answer_poll_id[$uid]}																		]]	&& break
			done
				
			(($?)) && continue

			for ent in ${_BOT_RULES_[$i:entities_type]//|/ }; do
				[[ $ent == @(${u_message_entities_type//$_BOT_DELM_/|})	]] 	&& break
			done

			(($?)) && continue
	
			for mem in ${_BOT_RULES_[$i:chat_member]//|/ }; do
				[[ $mem == new 	&& ${message_new_chat_member_id[$uid]} 	]] ||
				[[ $mem == left	&& ${message_left_chat_member_id[$uid]} ]] && break
			done
			
			(($?)) && continue

			for type in ${_BOT_RULES_[$i:file_type]//|/ }; do
				[[ $type == document 	&& ${message_document_file_id[$uid]:-${channel_post_document_file_id[$uid]}} &&
										 ! ${message_document_thumb_file_id[$uid]:-${channel_post_document_thumb_file_id[$uid]}}	]] 	||
				[[ $type == gif 		&& ${message_document_file_id[$uid]:-${channel_post_document_file_id[$uid]}} &&
										   ${message_document_thumb_file_id[$uid]:-${channel_post_document_thumb_file_id[$uid]}}	]] 	||
				[[ $type == photo		&& ${message_photo_file_id[$uid]:-${channel_post_photo_file_id[$uid]}}						]] 	||
				[[ $type == sticker 	&& ${message_sticker_file_id[$uid]:-${channel_post_sticker_file_id[$uid]}}					]]	||
				[[ $type == video		&& ${message_video_file_id[$uid]:-${channel_post_video_file_id[$uid]}}						]]	||
				[[ $type == audio		&& ${message_audio_file_id[$uid]:-${channel_post_audio_file_id[$uid]}}						]]	||
				[[ $type == voice		&& ${message_voice_file_id[$uid]:-${channel_post_voice_file_id[$uid]}}						]]	||
				[[ $type == contact		&& ${message_contact_user_id[$uid]:-${channel_post_contact_user_id[$uid]}}					]]	||
				[[ $type == location	&& ${message_location_latitude[$uid]:-${channel_post_location_latitude[$uid]}}				]]	&& break
			done

			(($?)) && continue
			
			[[ ${_BOT_RULES_[$i:time]} =~ $re ]]
			match=${BASH_REMATCH[2]:-${_BOT_RULES_[$i:time]}}

			for tm in ${match//|/ }; do
				IFS='-' read stime etime <<< $tm
				printf -v ctime '%(%H:%M)T' $u_message_date

				[[ $ctime == @($stime|$etime) 			]]	||
				[[ $ctime > $stime && $ctime < $etime 	]]	&& break
			done
					
			((${BASH_REMATCH[1]} $?)) && continue

			[[ ${_BOT_RULES_[$i:date]} =~ $re ]]
			match=${BASH_REMATCH[2]:-${_BOT_RULES_[$i:date]}}

			for dt in ${match//|/ }; do

				IFS='-' read sdate edate <<< $dt
				IFS='/' read -a sdate <<< $sdate
				IFS='/' read -a edate <<< $edate
					
				sdate=${sdate[2]}/${sdate[1]}/${sdate[0]}
				edate=${edate[2]}/${edate[1]}/${edate[0]}

				printf -v cdate '%(%Y/%m/%d)T' $u_message_date
					
				[[ $cdate == @($sdate|$edate) 			]] 	||
				[[ $cdate > $sdate && $cdate < $edate 	]]	&& break
			done
			
			((${BASH_REMATCH[1]} $?)) && continue

			if [[ ${_BOT_RULES_[$i:user_status]} ]]; then
				case $_BOT_TYPE_RETURN_ in
					value)
						out=$(TeleBot.getChatMember 	--chat_id $u_message_chat_id \
														--user_id $u_message_from_id 2>/dev/null)
							
						IFS=$_BOT_DELM_ read -a out <<< $out
						[[ ${out[2]} == true ]]
						status=${out[$(($? ? 6 : 5))]}
						;;
					json)
						out=$(TeleBot.getChatMember 	--chat_id $u_message_chat_id \
														--user_id $u_message_from_id 2>/dev/null)
							
						status=$(Json '.result.status' $out)
						;;
					map)	
						TeleBot.getChatMember 	--chat_id $u_message_chat_id \
												--user_id $u_message_from_id &>/dev/null

						status=${return[status]}
						;;
				esac
				[[ $status == @(${_BOT_RULES_[$i:user_status]}) ]] || continue
			fi
			
			# Monitor
			[[ $_BOT_MONITOR_ ]]	&& 	printf '[%s]: %s: %s: %s: %s: %s: %s: %s: %s: %s: %s\n'	\
										"${FUNCNAME}"											\
										"$((uid+1))"											\
										"$(printf '%(%d/%m/%Y %H:%M:%S)T' ${u_message_date})"	\
										"${u_message_chat_type}"								\
										"${u_message_chat_username:--}"							\
										"${u_message_from_username:--}"							\
										"${_BOT_RULES_[$i:source]}"								\
										"${_BOT_RULES_[$i:line]}"								\
										"${_BOT_RULES_[$i:name]}" 								\
										"${_BOT_RULES_[$i:action]:--}"							\
										"${_BOT_RULES_[$i:exec]:--}"
			
			# Log	
			[[ $_BOT_LOG_FILE_ ]] 	&&	printf '%s: %s: %s: %s: %s: %s: %s\n'	\
									 	"$(printf '%(%d/%m/%Y %H:%M:%S)T')"		\
								 	 	"${FUNCNAME}"							\
									 	"${_BOT_RULES_[$i:source]}"				\
									 	"${_BOT_RULES_[$i:line]}"				\
									 	"${_BOT_RULES_[$i:name]}"				\
										"${_BOT_RULES_[$i:action]:--}"			\
										"${_BOT_RULES_[$i:exec]:--}"			>> "$_BOT_LOG_FILE_"

			# Append Type of action. (if present)
			if [[ ${_BOT_RULES_[$i:bot_action]} ]]; then
				TeleBot.sendChatAction --chat_id $u_message_chat_id --action ${_BOT_RULES_[$i:bot_action]} &>/dev/null
			fi

			if [[ ${_BOT_RULES_[$i:bot_reply_message]} ]]; then
				TeleBot.sendMessage	--chat_id $u_message_chat_id 																\
										--reply_to_message_id $u_message_id															\
										--text "$(FlagConv $uid "${_BOT_RULES_[$i:bot_reply_message]}")" 							\
										${_BOT_RULES_[$i:bot_reply_markup]:+--reply_markup "${_BOT_RULES_[$i:bot_reply_markup]}"} 	\
										${_BOT_RULES_[$i:bot_parse_mode]:+--parse_mode ${_BOT_RULES_[$i:bot_parse_mode]}} 			&>/dev/null
			fi
				
			if [[ ${_BOT_RULES_[$i:bot_send_message]} ]]; then
				TeleBot.sendMessage	--chat_id $u_message_chat_id 																\
										--text "$(FlagConv $uid "${_BOT_RULES_[$i:bot_send_message]}")"								\
										${_BOT_RULES_[$i:bot_reply_markup]:+--reply_markup "${_BOT_RULES_[$i:bot_reply_markup]}"} 	\
										${_BOT_RULES_[$i:bot_parse_mode]:+--parse_mode ${_BOT_RULES_[$i:bot_parse_mode]}} 			&>/dev/null
			fi

			for fwid in ${_BOT_RULES_[$i:bot_forward_message]//|/ }; do
				TeleBot.forwardMessage		--chat_id $fwid						\
											--from_chat_id $u_message_chat_id 	\
											--message_id $u_message_id			&>/dev/null
			done

			# Call the function passing the positional arguments. (if it exists)
			${_BOT_RULES_[$i:action]:+${_BOT_RULES_[$i:action]} ${_BOT_RULES_[$i:action_args]:-${args[*]}}}
		
			# Run the command line and save the output.
			stdout=${_BOT_RULES_[$i:exec]:+$(set -- ${args[*]}; eval $(FlagConv $uid "${_BOT_RULES_[$i:exec]}") 2>&1)}

			while [[ $stdout ]]; do
				TeleBot.sendMessage	--chat_id $u_message_chat_id 			\
										--reply_to_message_id $u_message_id		\
										--text "${stdout:0:4096}"				&>/dev/null

				# Update the output buffer.
				stdout=${stdout:4096}
			
				# Resend action if there is still data.
				if [[ ${_BOT_RULES_[$i:bot_action]} && $stdout ]]; then
					TeleBot.sendChatAction --chat_id $u_message_chat_id --action ${_BOT_RULES_[$i:bot_action]} &>/dev/null
				fi
			done 
			[[ ${_BOT_RULES_[$i:continue]} ]] || return 0
		done

		return 1
	}

    TeleBot.getUpdates()
    {
    	local total_keys offset limit timeout allowed_updates jq_obj
	local vet val var obj oldv bar vars vals i

	# Define the parameters of the function
	local param=$(getopt 	--name "$FUNCNAME" \
				--options 'o:l:t:a:' \
				--longoptions 'offset:,
						limit:,
						timeout:,
						allowed_updates:' \
				-- "$@")
    
	eval set -- "$param"

    	while :
    	do
    		case $1 in
    			-o|--offset)
    				CheckArgType int "$1" "$2"
    				offset=$2
    				shift 2
    				;;
    			-l|--limit)
    				CheckArgType int "$1" "$2"
    				limit=$2
    				shift 2
    				;;
    			-t|--timeout)
    				CheckArgType int "$1" "$2"
    				timeout=$2
    				shift 2
    				;;
    			-a|--allowed_updates)
    				allowed_updates=$2
    				shift 2
    				;;
    			--)
    				# If there are no more parameters
    				shift 
    				break
    				;;
    		esac
    	done
    	
		# Set the parameters
		jq_obj=$(curl $_CURL_OPT_ POST $_API_TELEGRAM_/${FUNCNAME#*.} \
								${offset:+-d offset="$offset"} \
								${limit:+-d limit="$limit"} \
								${timeout:+-d timeout="$timeout"} \
								${allowed_updates:+-d allowed_updates="$allowed_updates"})


		# Clear initialized variables.
		unset $_VAR_INIT_; _VAR_INIT_=
		
		# Whether there are updates.
    	[[ $(jq -r '.result|length' <<< $jq_obj) -eq 0 ]] && return 0
	
		# If the 'TeleBot.getUpdates' method is invoked from a subshell,
		# updates are returned in a json data structure, the method
		# is terminated and variables are not initialized.
		[[ $BASH_SUBSHELL -gt 0 ]] && { echo "$jq_obj"; return 0; }

		if [[ $_BOT_MONITOR_ ]]; then
			printf -v bar '=%.s' {1..50}
			printf "$bar\nData: %(%d/%m/%Y %T)T\n"
			printf 'Script: %s\nBot (Name): %s\nBot (User): %s\nBot (Id): %s\n' 	\
					"${_BOT_SCRIPT_}" 												\
					"${_BOT_INFO_[2]}" 												\
					"${_BOT_INFO_[3]}" 												\
					"${_BOT_INFO_[1]}"
		fi
		
		mapfile -t vars <<< $(GetAllKeys "$jq_obj")
		mapfile -t vals <<< $(GetAllValues "$jq_obj")

		for i in ${!vars[@]}; do
	
			[[ ${vars[$i]} =~ [0-9]+ ]]
			vet=${BASH_REMATCH:-0}
			
			var=${vars[$i]//[0-9\[\]]/}
			var=${var#result.}
			var=${var//./_}
	
			declare -g $var
			local -n byref=$var # pointer
						
			val=${vals[$i]}
			val=${val#\"}
			val=${val%\"}

			byref[$vet]+=${byref[$vet]:+$_BOT_DELM_}${val}

			if [[ $_BOT_MONITOR_ ]]; then
				[[ $vet -ne ${oldv:--1} ]] && printf "$bar\nMessage: %d\n$bar\n" $((vet+1))
				printf "[%s]: %s = '%s'\n" "$FUNCNAME" "$var" "$val"
				oldv=$vet
			fi
	
			unset -n byref
			[[ $var != @(${_VAR_INIT_// /|}) ]] && _VAR_INIT_=${_VAR_INIT_:+$_VAR_INIT_ }${var}
		done
	
		# Log (thread)	
		[[ $_BOT_LOG_FILE_ ]] && CreateLog "${#update_id[@]}" "$jq_obj"

   		 # Status
   	 	return $?
	}
   
	# Bot methods (read-only)
	readonly -f TeleBot.token 								\
				TeleBot.id 									\
				TeleBot.username 							\
				TeleBot.first_name 							\
				TeleBot.getConfig							\
				TeleBot.regHandleFunction 					\
				TeleBot.regHandleExec						\
				TeleBot.watchHandle 						\
				TeleBot.ListUpdates 						\
				TeleBot.TotalUpdates 						\
				TeleBot.OffsetEnd 							\
				TeleBot.OffsetNext 							\
				TeleBot.getMe 								\
				TeleBot.getWebhookInfo 						\
				TeleBot.deleteWebhook 						\
				TeleBot.setWebhook 							\
				TeleBot.init 								\
				TeleBot.ReplyKeyboardMarkup 				\
				TeleBot.ForceReply							\
				TeleBot.ReplyKeyboardRemove					\
				TeleBot.KeyboardButton						\
				TeleBot.sendMessage 						\
				TeleBot.forwardMessage 						\
				TeleBot.sendPhoto 							\
				TeleBot.sendAudio 							\
				TeleBot.sendDocument 						\
				TeleBot.sendSticker 						\
				TeleBot.sendVideo 							\
				TeleBot.sendVideoNote 						\
				TeleBot.sendVoice 							\
				TeleBot.sendLocation 						\
				TeleBot.sendVenue 							\
				TeleBot.sendContact 						\
				TeleBot.sendChatAction 						\
				TeleBot.getUserProfilePhotos 				\
				TeleBot.getFile 							\
				TeleBot.kickChatMember 						\
				TeleBot.leaveChat 							\
				TeleBot.unbanChatMember 					\
				TeleBot.getChat 							\
				TeleBot.getChatAdministrators 				\
				TeleBot.getChatMembersCount 				\
				TeleBot.getChatMember 						\
				TeleBot.editMessageText 					\
				TeleBot.editMessageCaption 					\
				TeleBot.editMessageReplyMarkup 				\
				TeleBot.InlineKeyboardMarkup 				\
				TeleBot.InlineKeyboardButton 				\
				TeleBot.answerCallbackQuery 				\
				TeleBot.deleteMessage 						\
				TeleBot.exportChatInviteLink 				\
				TeleBot.setChatPhoto 						\
				TeleBot.deleteChatPhoto 					\
				TeleBot.setChatTitle 						\
				TeleBot.setChatDescription 					\
				TeleBot.pinChatMessage 						\
				TeleBot.unpinChatMessage 					\
				TeleBot.promoteChatMember 					\
				TeleBot.restrictChatMember 					\
				TeleBot.getStickerSet 						\
				TeleBot.uploadStickerFile 					\
				TeleBot.createNewStickerSet 				\
				TeleBot.addStickerToSet 					\
				TeleBot.setStickerPositionInSet 			\
				TeleBot.deleteStickerFromSet 				\
				TeleBot.stickerMaskPosition 				\
				TeleBot.downloadFile 						\
				TeleBot.editMessageLiveLocation 			\
				TeleBot.stopMessageLiveLocation 			\
				TeleBot.setChatStickerSet 					\
				TeleBot.deleteChatStickerSet 				\
				TeleBot.sendMediaGroup 						\
				TeleBot.editMessageMedia 					\
				TeleBot.inputMedia 							\
				TeleBot.sendAnimation 						\
				TeleBot.answerInlineQuery					\
				TeleBot.InlineQueryResult					\
				TeleBot.InputMessageContent					\
				TeleBot.ChatPermissions 					\
				TeleBot.setChatPermissions 					\
				TeleBot.setChatAdministratorCustomTitle 	\
				TeleBot.sendPoll							\
				TeleBot.KeyboardButtonPollType				\
				TeleBot.sendDice							\
				TeleBot.getMyCommands						\
				TeleBot.setMyCommands						\
				TeleBot.BotCommand							\
				TeleBot.setMessageRules 					\
				TeleBot.manageRules 						\
				TeleBot.getUpdates

	offset=${_BOT_FLUSH_:+$(FlushOffset)}	# flush
	printf -v jq_obj '{"token":"%s","id":%d,"first_name":"%s","username":"%s","offset_start":%d,"offset_end":%d}'	\
						"${_BOT_INFO_[0]}" 	\
						"${_BOT_INFO_[1]}" 	\
						"${_BOT_INFO_[2]}" 	\
						"${_BOT_INFO_[3]}" 	\
						"${offset%|*}"		\
						"${offset#*|}"

	# Returns bot information.
	MethodReturn "$jq_obj"

   	return $?
}

# Functions (read-only)
readonly -f MessageError 		\
			Json 				\
			FlushOffset 		\
			CreateUnitService 	\
			GetAllKeys 			\
			GetAllValues 		\
			SetDelmValues		\
			MethodReturn 		\
			CheckArgType 		\
			CreateLog			\
			FlagConv

# /* TELEBOT */
