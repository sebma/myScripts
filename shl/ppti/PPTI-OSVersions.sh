#!/usr/bin/env sh

pptiPrefix=ppti-14
timeOut=1
tcpProtocol=ssh
nbRoomPerFloor=9
nbMachinesPerRoom=4
macintoshRoom=ppti-14-409
pcList=""
for etage in $(seq 3 5)
do
	prefix="$pptiPrefix-$etage"
	for salle in $(printf "$prefix%02d " $(seq $nbRoomPerFloor))
	do
		echo "==> salle  = $salle" >&2
		for micro in $(printf "$salle-%02d " $(seq $nbMachinesPerRoom) | grep -v $macintoshRoom)
		do
			if ! host $micro | grep -v $micro
			then
				pcList="$pcList $micro"
				nc -v -z -w $timeOut $micro $tcpProtocol 2>/dev/null && echo "===> micro = $micro" >&2 && ssh $micro lsb_release -sr
			fi
		done
	done
done

echo "=> pcList = $pcList"

#macintoshList="$(printf "ppti-14-409-%02d " $(seq 20))"
macintoshList="$(printf "$macintoshRoom-%02d " $(seq $nbMachinesPerRoom))"
for macintosh in $macintoshList
do
	echo "=> macintosh = $macintosh" >&2
	if ! host $macintosh | grep -v $macintosh
	then
		nc -v -z -w $timeOut $macintosh $tcpProtocol 2>/dev/null && ssh $macintosh 'echo $OSTYPE'
	fi
done
