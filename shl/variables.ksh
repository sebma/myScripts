#!/usr/bin/env ksh

if mount | grep -q "/usr "; then
	for tool in awk cut egrep grep sed tee;do typeset $tool=$tool;done
else # Si /usr n'est pas monte, on utilise les applets busybox
	type busybox >/dev/null || exit
	for tool in awk cut egrep grep sed tee;do typeset $tool="busybox $tool";done
fi

echo "=> \$awk = $awk"
