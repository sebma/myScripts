#!/bin/bash

if [ -z $1 ]
then
	echo "*** No options given ***"
elif [ -n $1 ]
then
	param1=$1
	if [ -z $2 ]
	then
		echo "missing second parameter"
	elif [ -n $2 ]
	then
		param2=$2
		case $param2 in
			"start") systemctl start $param1.service ;;
			"stop") systemctl stop enable $param1.service ;;
			"restart") systemctl restart $param1.service ;;
			"reload") systemctl reload $param1.service ;;
			"condrestart") systemctl condrestart $param1.service ;;
			*) echo "unrecognized option $param2";;
		esac
	fi
fi
