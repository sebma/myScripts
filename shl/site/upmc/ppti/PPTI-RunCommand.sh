#!/usr/bin/env sh

pptiPrefix=ppti-14
timeOut=1
tcpProtocol=ssh
nbRoomPerFloor=9
nbMachinesPerRoom=2
macintoshRoom=ppti-14-409
pcList=""
commandToRun=$@

[ "$commandToRun" ] || {
	echo "=> ERROR: Usage $0 <commandToRun>" >&2
	exit 1
}

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
				nc -v -z -w $timeOut $micro $tcpProtocol 2>/dev/null && echo "===> micro = $micro" >&2 && ssh $micro $@
			fi
		done
	done
done

echo "=> pcList = $pcList"
