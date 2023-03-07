#!/usr/bin/env bash

if [ -s /usr/lib/ssl/misc/CA.pl ] && [ -x /usr/lib/ssl/misc/CA.pl ];then
	exec /usr/lib/ssl/misc/CA.pl "$@"
else
	scriptDir=$(dirname $0)
	scriptDir=$(cd $scriptDir;pwd)
	exec $scriptDir/not_mine/CA.pl "$@"
fi
