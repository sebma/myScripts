#!/usr/bin/env bash

set -u

sshClient=$(hostname -f)
sshServer=myRemote_SSH_SERVER
sshUser=my_SSH_User

ssh $sshUser@$sshServer : >/dev/null
if ssh $sshUser@$sshServer 2>&1 | grep 'CHANGED' -q;then
	Recipients="myEmail@address.domain"
	CCs=""
	echo "The SFTP server SSH host key has changed, you need to update your <$HOME/.ssh/known_hosts> file on the <$sftpClient> machine !
You need to check with your SFTP service provider if they changed the SSH host key.

Because the SFTP server SSH host key is NOW :
$(ssh-keyscan $sftpServer 2>&1 | grep -v '^#')

If they did change the SFTP server SSH host key, then you need to type these two commands as $USER to update the signature into the <$HOME/.ssh/known_hosts> file on the <$sftpClient> machine :

ssh-keygen -R $sftpServer

timeout 1s ssh -o StrictHostKeyChecking=accept-new $sshUser@$sftpServer : # Works since OpenSSH 7.6/Ubuntu 18.04 cf.
" | mail -s "ERROR: The $sftpServer SFTP server SSH key signature has changed !" -c "$CCs" $Recipients
	exit 255
fi
