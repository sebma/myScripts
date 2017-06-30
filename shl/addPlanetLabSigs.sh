#!/usr/bin/env bash

set -o nounset
set -o errexit

if [ $(ssh -V 2>&1 | cut -d_ -f2 | cut -d. -f1) -lt 6 ]
then
	printf "=> You cannot fetch <ssh-keygen -F> return code because OpenSSH is to old on that server: " >&2
	ssh -V
	exit 1
fi

hostsFile=~/.ssh/known_hosts
ip=""
for machine
do
	echo "=> machine = $machine"
	ip=$(dig +search +short $machine | egrep -vi "[a-z]" | egrep "[0-9.]+")
	echo "=> ip = $ip"
	ssh-keygen -F $machine >/dev/null || ssh ssh "ssh-keyscan -T 1 -H" $machine >> $hostsFile
	ssh-keygen -F $ip >/dev/null || ssh ssh "ssh-keyscan -T 1 -H $ip" >> $hostsFile
done

tmpFile=$(mktemp)
sort -u $hostsFile > $tmpFile
mv $tmpFile $hostsFile
