#!/usr/bin/env bash

set -o nounset

progBaseName=$(basename $0)
sourceServerType=$(uname -s)
test $# = 0 && {
  echo "=> Usage: <$progBaseName> <remote ssh server list>" >&2
  exit 1
}

##type puttygen >/dev/null 2>&1 || {
#  echo "=> <$progBaseName> ERROR: The <puttygen> tool is not installed." >&2
#  exit 2
#}

sshKeysDir=.ssh #Chemin relatif a $HOME
localPubKeyFilePrefix=id_rsa

if [ $sourceServerType = AIX ] || [ $sourceServerType = SunOS ]
then
  localPubKeyFilename=$USER.pub
else
  localPubKeyFilename=authorized_keys
fi

#Le "StrictModes" defini le controle des droits sur les fichiers et repertoires du user avant de presenter la cle publique
chmod go-w $HOME
umask 077
test -d $HOME/$sshKeysDir && chmod 700 $HOME/$sshKeysDir || mkdir $HOME/$sshKeysDir

privateKeyFileName=""
if [ ! -s $HOME/$sshKeysDir/$localPubKeyFilename ]
then
  echo "=> Telechargement de votre cle publique sur deurlx01, si elle existe ..."
  scp -p deurlx01:$sshKeysDir/$localPubKeyFilename $HOME/$sshKeysDir/ || {
  if type puttygen >/dev/null 2>&1
  then
    echo "=> Generation d'une bi-cle RSA au format "ssh.com" (PuTTY) avec l'outil puttygen, cela dure entre 30s et une minute ..."
    puttygen -q -t rsa -o $HOME/$sshKeysDir/$USER.ppk
    echo "=> Extraction de la cle publique du fichier $USER.ppk et conversion au format OpenSSH ..."
    puttygen $HOME/$sshKeysDir/$USER.ppk -L > $HOME/$sshKeysDir/$localPubKeyFilename
    privateKeyFileName=$HOME/$sshKeysDir/$USER.ppk
  else
    echo "=> Creating your ssh-key pair <$HOME/$sshKeysDir/$localPubKeyFilePrefix> and <$HOME/$sshKeysDir/$localPubKeyFilePrefix.pub> on server <$(hostname)> ..."
    echo
    echo "=> L'outil puttygen n'est pas installe, generation d'une bi-cle RSA au format OpenSSH, cela dure entre 30s et une minute ..."
    privateKeyFileName=$HOME/$sshKeysDir/$localPubKeyFilePrefix
    ssh-keygen -qf $HOME/$sshKeysDir/$localPubKeyFilePrefix && mv $HOME/$sshKeysDir/$localPubKeyFilePrefix.pub $HOME/$sshKeysDir/$localPubKeyFilename || {
      echo "=> Key pair not generated, please re-run <$progBaseName>." >&2
      exit 3
    }
  fi
  }
else
  echo "=> La cle publique est deja presente sur <$(hostname)>."
fi


echo "=> Setting the correct rights for your ssh files ..."
chmod 600 $HOME/$sshKeysDir/$localPubKeyFilename

umask 022

printf "=> What is the remote server type [AIX/Solaris/HP-UX/Linux] ? "
read remoteServerType
remoteServerType=$(echo "$remoteServerType" | tr [:upper:] [:lower:])
case $remoteServerType in
  aix|solaris|hp-ux) remotePubKeyFilename=$USER.pub;;
  linux)	     remotePubKeyFilename=authorized_keys;;
  *) echo "=> ERROR: Unknown OS type." >&2 && exit 4 ;;
esac
echo

#pubKeyFingerPrint=$(ssh-add -l | awk '{print$2}')
localPubKeyFingerPrint=$(ssh-keygen -lf $HOME/$sshKeysDir/$localPubKeyFilename | awk '{print$2}')
for remoteServer
do
  echo "=> You will be prompted twice to enter your password ..."
  echo "=> Testing if public key already exist on <$remoteServer> ..."
  ssh $remoteServer "test -s $sshKeysDir/$remotePubKeyFilename" && {
    remotePubKeyFingerPrint=$(ssh $remoteServer "ssh-keygen -lf $sshKeysDir/$remotePubKeyFilename" 2>/dev/null | awk '{print$2}')
    echo "=> Public key already exist on <$remoteServer>, setting the correct rights for your ssh files ..."
    ssh $remoteServer "chmod go-w .;chmod 700 $sshKeysDir;chmod 600 $sshKeysDir/$remotePubKeyFilename"
  } || {
    echo "=> Creating remote .ssh directory, uploading your ssh keys to the server <$remoteServer> and setting the rights according to <StrictModes> and <AuthorizedKeysFile> SG policies ..."
    cat $HOME/$sshKeysDir/$localPubKeyFilename | ssh $remoteServer "chmod go-w .;umask 077;mkdir -p $sshKeysDir;grep -q ssh-rsa $sshKeysDir/$remotePubKeyFilename && cat >> $sshKeysDir/$remotePubKeyFilename || cat > $sshKeysDir/$remotePubKeyFilename;"
  }
done

echo
test $privateKeyFileName && {
  echo "=> Don't forget to download your ssh private key file : $privateKeyFileName to your Desktop for PuTTY to use."
  test $privateKeyFileName = $HOME/$sshKeysDir/$USER.ppk || {
    echo "=> This key is a OpenSSH private, you have to import and convert to SSH.com format using PuTTYGen before using it."
  }
}
echo

#grep -q ssh-agent $HOME/.profile || {
#  echo echo "=> Loading the SSH authentication agent ..."
#  echo 'ps -fu $USER | grep -v grep | grep -q ssh-agent || eval $(ssh-agent -s)'
#} >> $HOME/.profile

#ps -fu $USER | grep -v grep | grep -q ssh-agent || eval $(ssh-agent -s)
#ssh-add $HOME/$sshKeysDir/$localPubKeyFilePrefix
