#!/bin/bash

if [ $# != 2 ]
then
	echo "Usage : $0 serviceName start|stop|status|restart|reload|condrestart" >&2
	exit 1
else
	serviceName=$1
	action=$2
	case $action in
		"start") systemctl start $serviceName.service ;;
		"status") systemctl status $serviceName.service ;;
		"stop") systemctl stop enable $serviceName.service ;;
		"restart") systemctl restart $serviceName.service ;;
		"reload") systemctl reload $serviceName.service ;;
		"condrestart") systemctl condrestart $serviceName.service ;;
		*) echo "unrecognized option $action";;
	esac
fi
