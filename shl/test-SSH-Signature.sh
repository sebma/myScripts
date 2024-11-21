#!/usr/bin/env bash

set -u

sshClient=$(hostname -f)
sshServer=myRemote_SSH_SERVER
sshUser=my_SSH_User

ssh $sshUser@$sshServer >/dev/null
if ssh $sshUser@$sshServer 2>&1 | grep 'CHANGED' -q;then
	Recipients="myEmail@address.domain"
	CCs=""
	(
	ssh $sshUser@$sshServer 2>&1
	echo
	echo
	echo
	echo "=> You need to type this command as $USER to update $HOME/.ssh/known_hosts on $sshClient :"
	echo "ssh-keygen -f $HOME/.ssh/known_hosts -R $sshServer"
	) | mail -s "ERROR: The SSH server SSH key signature has changed, you need to update $HOME/.ssh/known_hosts on $sshClient." -c "$CCs" $Recipients
	exit 255
fi
