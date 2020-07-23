#!/usr/bin/env sh

pingMyLAN ()
{
	local myLAN=$(\ip addr show | awk '/inet /{print$2}' | egrep -v '127.0.0.[0-9]|192.168.122.[0-9]')
	if which fping > /dev/null 2>&1; then
		time fping -r 0 -aAg $myLAN 2> /dev/null | sort -u
	else
		time \nmap -T5 -sP $myLAN | sed -n '/Nmap scan report for /s/Nmap scan report for //p'
	fi
}

pingMyLAN
