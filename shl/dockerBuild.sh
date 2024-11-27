#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

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

	( [ ! -f "$dockerFile" ] || [ ! -d "$dir" ] ) && echo "[$FUNCNAME] => ERROR: <$dockerFile> or <$dir> does not exits.">&2 && return 1
	set -x
	time docker build --no-cache -t "$imageName" -f "$dockerFile" "$dir" "$@" && echo && docker images "$imageName" && echo && echo "=> docker run -it -h pc1 --rm $imageName"
	return $?
}

dockerBuild "$@"
