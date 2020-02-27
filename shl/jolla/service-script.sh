#!/bin/bash

if [ $# = 0 ];then
	systemctlCommands=$(systemctl -h | sed -n '/Commands:/,$p' | awk '!/Commands:|^$|^   /{printf$1"|"}' | sed "s/.$//")
	echo "Usage : ${0/*\//} serviceName $systemctlCommands" >&2
	exit 1
elif [ $# = 1 ];then
	systemctl $1
else
	serviceName=$1
	action=$2
	shift 2
	systemctl $action "$@" $serviceName
fi
