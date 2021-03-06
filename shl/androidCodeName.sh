#!/bin/bash

shopt -s extglob

function androidCodeName {
	( [ $# -ge 2 ] || echo $1 | egrep -q -- "^--?(h|u)" ) && echo "=> Usage : $FUNCNAME [androidRelease]" 1>&2 && return 1
	
	local androidRelease=unknown
	local androidCodeName=unknown
	if echo $1 | egrep -q "[0-9.]+"; then
		androidRelease=$1 
		androidCodeName="REL" # Do not use "androidCodeName" when it equals to "REL" but infer it from "androidRelease"
	elif [ -n "$(getprop ro.build.version.release 2>/dev/null)" ]; then
		androidRelease=$(getprop ro.build.version.release)
		androidCodeName=$(getprop ro.build.version.codename)
	else
		echo "=> [$FUNCNAME] ERROR: Could not detect android release on this device" >&2
		return 2
	fi

	# Time "androidRelease" x10
	case $androidRelease in
		+([0-9]).+([0-9])?(.)?([0-9]) )  androidRelease=$(echo $androidRelease | cut -d. -f1-2 | tr -d .);;
		+([0-9]). ) androidRelease=$(echo $androidRelease | sed 's/\./0/');;
		+([0-9]) ) androidRelease+="0";;
	esac

	[ -n "$androidRelease" ] && [ $androidCodeName = REL ] && {
	# Do not use "androidCodeName" when it equals to "REL" but infer it from "androidRelease"
		androidCodeName="${colors[blue]}"
		case $androidRelease in
		10) androidCodeName+=NoCodename;;
		11) androidCodeName+="Petit Four";;
		15) androidCodeName+=Cupcake;;
		20|21) androidCodeName+=Eclair;;
		22) androidCodeName+=FroYo;;
		23) androidCodeName+=Gingerbread;;
		30|31|32) androidCodeName+=Honeycomb;;
		40) androidCodeName+="Ice Cream Sandwich";;
		41|42|43) androidCodeName+="Jelly Bean";;
		44) androidCodeName+=KitKat;;
		50|51) androidCodeName+=Lollipop;;
		60) androidCodeName+=Marshmallow;;
		70|71) androidCodeName+=Nougat;;
		80|81) androidCodeName+=Oreo;;
		90) androidCodeName+=Pie;;
		100) androidCodeName+=ToBeReleased;;
		*) androidCodeName=${colors[red]}unknown;;
		esac
	}
	echo $androidCodeName$normal
}

androidCodeName "$@"
