#!/usr/bin/env bash

scriptBaseName=${0/*\//}

dockerBuild () {
	set +u
	local imageName="$1"
	local dockerFile="$2"
	local dir="$3"

	set -u
	if [ $# = 2 ];then
		dir=.
		shift 2
	elif [ $# = 3 ];then
		shift 3
	elif [ $# -lt 2 ];then
		echo "[$FUNCNAME] => INFO: Usage: $scriptBaseName imageName dockerFile [dir = .]" >&2
		return -1
	fi

	( [ ! -f "$dockerFile" ] || [ ! -d "$dir" ] ) && echo "[$FUNCNAME] => ERROR: <$dockerFile> or <$dir> does not exits.">&2 && return 1
	set -x
	time docker build --no-cache -t "$imageName" -f "$dockerFile" "$dir" "$@" && echo && docker images "$imageName" && echo && echo "=> docker run -it -h pc1 --rm $imageName"
	return $?
}

dockerBuild "$@"
