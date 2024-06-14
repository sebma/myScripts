#!/usr/bin/env bash

function osSize {
	#La partition swap n'est pas prise en compte pour le moment
	LC_NUMERIC=C
	local df="command df"
	echo $OSTYPE | grep -q android && export osFamily=Android || export osFamily=$(uname -s)
	if [ $osFamily = Linux ];then
		time $df -T | awk 'BEGIN{printf "df -T "} !/tmpfs/ && !/efivarfs/ && /\/$|boot$|opt|tmp$|usr|var/{printf $NF" "}' | sh -x | awk '{total+=$4}END{print total/1024^2" GiB"}'
		echo
		time $df -T | awk 'BEGIN{printf "sudo du -cxsk "} !/tmpfs/ && !/efivarfs/ && /\/$|boot$|opt|tmp$|usr|var/{printf $NF" "}' | sh -x | awk '/[\t ]+total$/{print$1/1024^2" GiB"}'
	else
		echo "=> [${0/*\//}] ERROR : $osFamily is not supported yet." >&2
	fi
}

osSize "$@"
