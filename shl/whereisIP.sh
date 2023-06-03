#!/usr/bin/env sh

whereisIP () {
	local output="$(type -P curl >/dev/null && \curl -sA "" ipinfo.io/$1 || \wget -qO- -U "" ipinfo.io/$1)"
	local outputDataType=$(echo "$output" | file -bi -)
	case $outputDataType in
		text/html*)
			echo "$output" | html2text
		;;
		application/json*)
			echo "$output" | jq .
		;;
		text/plain*)
			echo "$output"
		;;
		*)
			echo "Unknown data type." 1>&2
			exit 1
		;;
	esac
}

whereisIP "$@"
