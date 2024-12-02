#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}
test $(id -u) == 0 && sudo="" || sudo=sudo

dockerBuild () {
	local imageName=""
	local dockerFile=""
	local dir="."

	if [ $# = 2 ];then
		imageName="${1,,}"
		dockerFile="$2"
		shift 2
	elif [ $# = 3 ];then
		imageName="${1,,}"
		dockerFile="$2"
		dir="$3"
		shift 3
	elif [ $# -lt 2 ];then
		echo "[function $FUNCNAME] => INFO: Usage: $scriptBaseName imageName dockerFile [dir = .]" >&2
		return -1
	fi

	if [ ! -f "$dockerFile" ] || [ ! -d "$dir" ];then
		echo "[$FUNCNAME] => ERROR: <$dockerFile> or <$dir> does not exits.">&2
		return 1
	fi

	set -x
#	time $sudo docker build --no-cache -t "$imageName" -f "$dockerFile" "$dir" "$@"
	time $sudo docker build -t "$imageName" -f "$dockerFile" "$dir" "$@"
	retCode=$?
	set +x

	if [ $retCode == 0 ];then
		echo && $sudo docker images "$imageName" && echo && echo "=> $sudo docker run -it -h pc1 --rm --network=host $imageName"
	fi
	return $retCode
}

dockerBuild "$@"
