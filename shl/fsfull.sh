#!/usr/bin/env bash

interpreter=`ps -o pid,comm | awk /$$/'{print $2}'`
echo "=> interpreter = $interpreter"
sleep 10

linuxServers="pingoin01 pingoin02"
for linux in $linuxServers
do
	echo "=> Linux server = $linux"
	nc -vz $linux ssh 2>&1 | grep -q succeeded && ssh $linux df 2>/dev/null	| awk /%/'{print$(NF-1)" "$NF}' | grep -v cdrom | egrep --color "(9)[0-9]%|100%"
	echo
done

aixServers="toto01 toto02"
for aix in $aixServers
do
	echo "=> AIX server = $aix"
	nc -vz $aix ssh 2>&1 | grep -q succeeded && ssh $aix "df -P" 2>/dev/null | awk /%/'{print$(NF-1)" "$NF}' | grep -v cdrom | egrep --color "(9)[0-9]%|100%"
	echo
done

