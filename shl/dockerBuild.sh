#!/usr/bin/env bash

dockerBuild () {
	local imageName="$1"
	local dockerFile="$2"
	local dir="$3"

	if [ $# = 2 ];then
		dir=.
		shift 2
	elif [ $# = 3 ];then
		shift 3
	elif [ $# -lt 2 ];then
		echo "=> $FUNCNAME imageName dockerFile [dir = .]" >&2
		return 1
	fi

	time docker build -t "$imageName" -f "$dockerFile" "$dir" "$@" && docker images "$imageName" && echo "=> docker run -it --rm $imageName"
	return $?
}

dockerBuild "$@"
