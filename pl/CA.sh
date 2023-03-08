#!/usr/bin/env bash

function CA {
	local CAToolPath=$(locate -r /CA.pl$ | grep -v /snap/ | grep ^/usr/)
	if [ ! -s $CAToolPath ];then
		scriptDir=$(dirname $0)
		scriptDir=$(cd $scriptDir;pwd)
		CAToolPath=$scriptDir/not_mine/CA.pl
	fi

	exec $CAToolPath "$@"
}

CA "$@"
