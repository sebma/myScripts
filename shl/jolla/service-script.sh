#!/bin/bash

if [ $# = 0 ];then
	systemctlCommands=$(systemctl -h | awk '/Commands:/,EOF { if( !/^$|^   |Commands:/ ) cmds=cmds$1"|";} END { print gensub("[|]$","",1,cmds) }')
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
