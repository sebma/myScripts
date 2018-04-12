#!/usr/bin/env bash

set -o nounset
set -o errexit

if [ $($(which ssh) -V 2>&1 | cut -d_ -f2 | cut -d. -f1) -lt 6 ]
then
    printf "=> You cannot fetch <ssh-keygen -F> return code because OpenSSH is to old on that server: " >&2
	$(which ssh) -V
    exit 1
fi

pptiPrefix=ppti-14
timeOut=1
tcpProtocol=ssh
nbRoomPerFloor=1
nbMachinesPerRoom=20
macintoshRoom=ppti-14-409
lastFloor=3
pcList=""
for etage in $(seq 3 $lastFloor)
do
	echo "=> etage = $etage"
	prefix="$pptiPrefix-$etage"
	for salle in $(printf "$prefix%02d " $(seq $nbRoomPerFloor))
	do
		echo "=> salle = $salle"
		for micro in $(printf "$salle-%02d " $(seq $nbMachinesPerRoom) | grep -v $macintoshRoom)
		do
			echo "=> micro = $micro"
			if ! host $micro | grep -v $micro
			then
				nc -v -z -w $timeOut $micro $tcpProtocol 2>/dev/null && pcList="$pcList $micro"
			fi
		done
	done
done

echo "=> pcList = $pcList"

#macintoshList="$(printf "ppti-14-409-%02d " $(seq 20))"
macintoshList="$(printf "$macintoshRoom-%02d " $(seq $nbMachinesPerRoom))"
macList=""
for macintosh in $macintoshList
do
	if ! host $macintosh | grep -v $macintosh
	then
		nc -v -z -w $timeOut $macintosh $tcpProtocol 2>/dev/null && macList="$macList $macintosh"
	fi
done

echo "=> macList= $macList"

machineList="$pcList $macList"
#machineList=ppti-14-403-12
echo "=> machineList = $machineList"

function addSSHSig {
    machine=$1
    ip=$(dig +search +short $machine | egrep -vi "[a-z]" | egrep "[0-9.]+")
    hostsFile=~/.ssh/known_hosts
    ssh-keygen -F $machine >/dev/null || ssh-keyscan -T 1 -H $machine >> $hostsFile
    ssh-keygen -F $ip >/dev/null || ssh-keyscan -T 1 -H $ip >> $hostsFile
}

hostsFile=~/.ssh/known_hosts
for machine in $machineList
do
	#addSSHSig $machine
	:
done

tmpFile=$(mktemp)
sort -u $hostsFile > $tmpFile
mv $tmpFile $hostsFile
