#!/usr/bin/env bash

set -u

sftpClient=$(hostname -f)
sftpServer=myRemote_SSH_SERVER
sftpUser=my_SSH_User

ssh $sftpUser@$sftpServer : >/dev/null
if ssh $sftpUser@$sftpServer 2>&1 | grep 'CHANGED' -q;then
	Recipients="myEmail@address.domain"
	CCs=""
	echo "The <$sftpServer> server SSH host key has changed, you need to update your <$HOME/.ssh/known_hosts> file on the <$sftpClient> machine !
You need to check with your <$sftpServer> server service provider if they changed the SSH host key.

Because the <$sftpServer> server SSH host key is NOW :
$(ssh-keyscan $sftpServer 2>&1 | grep -v '^#')

If they did change the <$sftpServer> server SSH host key, then you need to type these two commands as $USER to update the signature into the <$HOME/.ssh/known_hosts> file on the <$sftpClient> machine :

ssh-keygen -R $sftpServer

timeout 1s ssh -o StrictHostKeyChecking=accept-new $sftpUser@$sftpServer : # Works since OpenSSH 7.6/Ubuntu 18.04 cf. https://serverfault.com/a/903635/312306
" | mail -s "ERROR: The <$sftpServer> server SSH host key signature has changed !" -c "$CCs" $Recipients
	exit 255
fi
