#!/bin/bash

declareShellTools () {
	tools="awk cut egrep grep sed tee"
	if mount | grep -q "/usr "; then
		for tool in $tools;do export $tool=$tool;done
	else # Si /usr n'est pas monte, on utilise les applets busybox
		type busybox >/dev/null || exit
		for tool in $tools;do export $tool="busybox $tool";done
	fi
}

declareShellTools || exit
echo "=> \$awk = $awk"

main () {
	tools="awk cut egrep grep sed tee sort"
	if mount | grep -q "/usr "; then
		for tool in $tools;do declare $tool=$tool;done
	else # Si /usr n'est pas monte, on utilise les applets busybox
		type busybox >/dev/null || exit
		for tool in $tools;do declare $tool="busybox $tool";done
	fi
	echo "=> \$tee = $tee"
}
main || exit
echo "=> \$sort = $sort"
