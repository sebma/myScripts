#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}
test $(id -u) == 0 && sudo="" || sudo=sudo

dockerBuild () {
	local imageName=""
	local imageRelease="v0.0.1"
	local dockerFileName=""
	local dir="."

	if [ $# = 1 ];then
		dockerFileName="$1"
		shift 1
	elif [ $# = 2 ];then
		imageRelease="${1,,}"
		dockerFileName="$2"
		shift 2
	elif [ $# = 3 ];then
		imageRelease="${1,,}"
		dockerFileName="$2"
		dir="$3"
		shift 3
	elif [ $# = 0 ];then
		echo "[function $FUNCNAME] => INFO: Usage: $scriptBaseName [imageRelease=v0.0.1] [dir = .] dockerFileName" >&2
		return -1
	fi

	imageName=${dockerFileName/*\//}
	imageName=${imageName/Dockerfile/$USER}
	imageName=${imageName,,}:$imageRelease

	if [ ! -f "$dockerFileName" ] || [ ! -d "$dir" ];then
		echo "[$FUNCNAME] => ERROR: <$dockerFileName> or <$dir> does not exits.">&2
		return 1
	fi

	if env | grep apt_proxy -q ;then
		set -x
		time $sudo docker build --build-arg apt_proxy=$apt_proxy -t "$imageName" -f "$dockerFileName" "$dir" "$@"
	else
		set -x
		time $sudo docker build -t "$imageName" -f "$dockerFileName" "$dir" "$@"
	fi
	retCode=$?
	set +x

	if [ $retCode == 0 ];then
		echo && $sudo docker images "$imageName" && echo && echo "=> $sudo docker run -it -h pc1 --rm --network=host $imageName bash -l"
	fi
	return $retCode
}

dockerBuild "$@"
