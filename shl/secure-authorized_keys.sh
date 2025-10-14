#!/usr/bin/env bash

#sshOptions="no-port-forwarding no-X11-forwarding no-agent-forwarding no-pty"
sshOptions="no-port-forwarding no-X11-forwarding no-agent-forwarding"
for sshOption in $sshOptions;do
	if ! grep $sshOption ~/.ssh/authorized_keys -q;then
		sed -i "s/^/$sshOption,/" ~/.ssh/authorized_keys
	fi
done
sed -i 's/,ssh-/ ssh-/' ~/.ssh/authorized_keys
