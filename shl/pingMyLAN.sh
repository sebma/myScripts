#!/usr/bin/env bash

pingMyLAN ()
{
	local myOutgoingInterFace=$(ip route | awk '/default/{print$5}')
	local myLAN=$(ip -4 addr show dev $myOutgoingInterFace scope global up | awk -F " *|/" '/inet/{print$3}')
 	local prefix=$(ip -4 addr show dev $myOutgoingInterFace scope global up | awk -F " *|/" '/inet/{print$4}')
  	local lanPrefix=$(echo $myLAN | cut -d. -f1-3)
 	local nbHost=$((2**(32-$prefix)))
	if [ $# = 0 ]; then
		if type -P fping > /dev/null 2>&1; then
			time fping -r 0 -aAg $myLAN/$prefix 2> /dev/null | sort -u
		elif type -P nmap > /dev/null 2>&1; then
			time \nmap -T5 -sP $myLAN/$prefix | sed -n '/Nmap scan report for /s/Nmap scan report for //p'
   		else
     			time for i in $(seq $nbHost); do ping $lanPrefix.$i -c1 -W1 & done | grep from
		fi
	elif [ $# = 1 ]; then
		port=$1
		if type -P fping > /dev/null 2>&1; then
			time \nmap -T5 -sP $myLAN/$prefix | sed -n '/Nmap scan report for /s/Nmap scan report for //p' | while read ip
			do
				tcpConnetTest $ip $port
			done
		fi
	fi
}

pingMyLAN
