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

#macintoshList="$(printf "ppti-14-409-%02d " $(seq 20))"
macintoshList="$(printf "$macintoshRoom-%02d " $(seq $nbMachinesPerRoom))"
for macintosh in $macintoshList
do
	echo "=> macintosh = $macintosh" >&2
	if ! host $macintosh | grep -v $macintosh
	then
		nc -v -z -w $timeOut $macintosh $tcpProtocol 2>/dev/null && ssh $macintosh $@
	fi
done
