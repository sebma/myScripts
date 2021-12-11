#!/usr/bin/env bash

[ $1 ] || {
	echo "=> Usage : $(basename $0) <roomPrefix>" >&2
#	Example : testPPTI-SSH.sh $(printf "ppti-14-3%02d " $(seq 9)
	exit 1
}

timeOut=1
nbMicro=20
tcpProtocol=ssh
for roomPrefix
do
	for micro in $(printf "$roomPrefix-%02d " $(seq $nbMicro))
	do
		host $micro | grep -v $micro || nc -v -z -w $timeOut $micro $tcpProtocol
	done
done
