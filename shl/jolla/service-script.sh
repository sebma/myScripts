#!/bin/bash

if [ $# != 2 ]
then
	echo "Usage : $0 serviceName start|stop|status|restart|reload|cat|show" >&2
	exit 1
else
	serviceName=$1
	action=$2
	case $action in
		start|stop|status|restart|reload|cat|show) systemctl $action $serviceName;;
		daemon-reload) systemctl $action;;
		*) echo "Unknown operation $action" >&2;exit 1;;
	esac
fi
