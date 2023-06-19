#!/usr/bin/env bash

pingMyLAN ()
{
	local myOutgoingInterFace=$(ip route | awk '/default/{print$5}')
	local myLAN=$(\ip -4 addr show dev $myOutgoingInterFace scope global up | awk '/inet/{print$2}')
	if [ $# = 0 ]; then
		if type -P fping > /dev/null 2>&1; then
			time fping -r 0 -aAg $myLAN 2> /dev/null | sort -u
		else
			time \nmap -T5 -sP $myLAN | sed -n '/Nmap scan report for /s/Nmap scan report for //p'
		fi
	elif [ $# = 1 ]; then
		port=$1
		if type -P fping > /dev/null 2>&1; then
			time \nmap -T5 -sP $myLAN | sed -n '/Nmap scan report for /s/Nmap scan report for //p' | while read ip
			do
				tcpConnetTest $ip $port
			done
		fi
	fi
}

pingMyLAN
