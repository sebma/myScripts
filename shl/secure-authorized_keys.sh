#!/usr/bin/env bash

authorized_keysFile=~/.ssh/authorized_keys
#sshOptions="no-port-forwarding no-X11-forwarding no-agent-forwarding no-pty"
sshOptions="no-port-forwarding no-X11-forwarding no-agent-forwarding"
while read line;do
	for sshOption in $sshOptions;do
		if ! echo $line | grep $sshOption -q;then
			printf $sshOption,
		fi
	done
	echo $line
done < $authorized_keysFile > $authorized_keysFile.new
mv -f $authorized_keysFile.new $authorized_keysFile
sed -i 's/,ssh-/ ssh-/' $authorized_keysFile
sed -i 's/,sk-/ sk-/' $authorized_keysFile
chmod 600 $authorized_keysFile
