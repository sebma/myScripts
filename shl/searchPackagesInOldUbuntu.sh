#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

function searchPackagesInOldUbuntu {
	local distribName=""
	local packageRegExp=""
	local component=""
	local suite=""
	local archi=$(dpkg --print-architecture)

	if [ $# == 2 ];then
		distribName=$1
		packageRegExp="$2"
	else
		echo "[function $FUNCNAME] => INFO: Usage: $scriptBaseName distribName packageRegExp" >&2
        return -1
	fi

	for suite in $(printf "$distribName%s " "" -backports -proposed -security -updates)
	do
		echo "=> suite = $suite"
		for component in main multiverse restricted universe
		do
			echo "==> component = $component"
			set -o pipefail
			curl -s https://archive.ubuntu.com/ubuntu/dists/$suite/$component/binary-$archi/Packages.gz | gunzip -c | egrep "Package:.$packageRegExp" -A10 | egrep "Package:|Version:"
			set +o pipefail
		done
	done
}

searchPackagesInOldUbuntu "$@"
