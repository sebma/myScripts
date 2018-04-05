#!/usr/bin/env ksh

set -o nounset
set -o errexit

progBaseName=$(basename $0)

function funcname {
	funcnameVar=$(env | grep -q FUNCNAME && echo FUNCNAME || echo 0)
	echo echo "=\> funcName = " \$$funcnameVar
}

function initColors {
	eval $(funcname) >&2
	typeset escapeChar=$'\e'
	normal="$escapeChar[m"
	bold="$escapeChar[1m"
	blink="$escapeChar[5m"
	blue="$escapeChar[34m"
	cyan="$escapeChar[36m"

	yellowOnRed="$escapeChar[33;41m"

	greenOnBlue="$escapeChar[32;44m"
	yellowOnBlue="$escapeChar[33;44m"
	cyanOnBlue="$escapeChar[36;44m"
	whiteOnBlue="$escapeChar[37;44m"

	redOnGrey="$escapeChar[31;47m"
	blueOnGrey="$escapeChar[34;47m"
}

initColors

function clean_exit {
	eval $(funcname) >&2
	test $1 && rc=$1
	echo "=> DEBUT de la fonction <clean_exit> d'arret propre du programme."
	echo "=> FIN de la fonction <clean_exit> d'arret propre du programme."
	echo
	echo "=> The log file is <$logDir/$logFile>." >&2
	exec 1>&- 2>&-
	wait $stdout_tee_PID
	wait $stderr_tee_PID
	rm -f $logDir/$logFile.pipe $logDir/$logFile-err.pipe
	chmod -w $logDir/$logFile

	exit $rc #Ne pas mettre de "return" dans une fonction appellee par une trappe sinon le "return" envoi un autre SIGINT qui est alors re-trappe et on pars en boucle
}

function initLog {
	eval $(funcname) >&2
	logDir=/var/log/$(echo $progBaseName | sed "s/\..*//")
	test -d $logDir || {
		echo "=> [$progBaseName][initLog] ERROR: The directory <$logDir> does not exists."
		exit 1
	}
	logDir=$(cd $logDir;pwd)
	test -w $logDir || {
		echo "=> [$progBaseName][initLog] ERROR: You don't have write permissions to the directory <$logDir>."
		exit 2
	}
	logFile=${progBaseName}_${USER}_$(date +%Y%m%d_%HH%M_%S).log
}

initLog

#Creation de 2 FIFOs pour la duplication de stdout et de stderr.
mkfifo $logDir/$logFile.pipe $logDir/$logFile-err.pipe
tee -a $logDir/$logFile < $logDir/$logFile.pipe &
stdout_tee_PID=$!
tee -a $logDir/$logFile < $logDir/$logFile-err.pipe >&2 &
stderr_tee_PID=$!
exec 1> $logDir/$logFile.pipe
exec 2> $logDir/$logFile-err.pipe

function initScript {
	eval $(funcname) >&2
	echo "=> Lancement du script <$progBaseName> implemente par Sebastien MANSFELD :-)"

	test $# = 0 && {
		echo "=> Usage: <$progBaseName> <remote ssh server list>" >&2
		exit 1
	}

	firstServer=$1

	type puttygen >/dev/null 2>&1 || {
		echo "=> <$progBaseName> ERROR: The <puttygen> tool is not installed." >&2
		exit 2
	}
}

initScript $@

function initKeys {
	eval $(funcname) >&2
	sshKeysDir=.ssh #Chemin relatif a $HOME
	localPubKeyFilePrefix=id_rsa

	echo
	echo "=> Vous etes <$USER>: $(awk -F":|," /$USER/'{print$5}' /etc/passwd)."
	sourceServerType=$(uname -s)
	if [ $sourceServerType = AIX ] || [ $sourceServerType = SunOS ]
	then
		localPubKeyFileBasename=$USER.pub
	else
		localPubKeyFileBasename=authorized_keys
	fi
	localPubKeyFileName=$HOME/$sshKeysDir/$localPubKeyFileBasename

	#Le "StrictModes" defini le controle des droits sur les fichiers et repertoires du user avant de presenter la cle publique
	chmod go-w $HOME
	umask 077
	test -d $HOME/$sshKeysDir && chmod 700 $HOME/$sshKeysDir || mkdir $HOME/$sshKeysDir

	privateKeyFileName=""
	firstServer=$1
	if [ ! -s $localPubKeyFileName ]
	then
		echo "=> Telechargement de votre cle publique sur le premier serveur: <$firstServer>, si elle existe ..."
		if scp -p $firstServer:$sshKeysDir/$localPubKeyFileBasename $HOME/$sshKeysDir/
		then
			shift
		else
			echo "=> Il n'a pas de cle publique pre-existante sur <$firstServer>. " >&2
			if type puttygen >/dev/null 2>&1
			then
				privateKeyFileName=$HOME/$sshKeysDir/$USER.ppk
				echo "=> Generation d'une bi-cle RSA au format "ssh.com" (PuTTY) avec l'outil puttygen, cela dure entre 30s et une minute ..."
				puttygen -q -t rsa -o $privateKeyFileName
				echo "=> Extraction de la cle publique du fichier $(basename $privateKeyFileName) et conversion au format OpenSSH ..."
				puttygen $privateKeyFileName -O public-openssh > $localPubKeyFileName
			else
				privateKeyFileName=$HOME/$sshKeysDir/$localPubKeyFilePrefix
				echo "=> Creating your ssh-key pair <$privateKeyFileName> and <$privateKeyFileName.pub> on server <$(hostname)> ..."
				echo
				echo "=> L'outil puttygen n'est pas installe, generation d'une bi-cle RSA au format OpenSSH, cela dure entre 30s et une minute ..."
				if ssh-keygen -qf $privateKeyFileName
				then
					mv $privateKeyFileName.pub $localPubKeyFileName
				else
					echo "=> The ssh key pair could not be generated, please re-run <$progBaseName>." >&2
					clean_exit 3
				fi
			fi
		fi
	else
		echo "=> La cle publique est deja presente sur <$(hostname)>."
	fi
	umask 022

	echo "=> Setting the correct rights for your ssh files ..."
	chmod 600 $localPubKeyFileName
	localPubKeyFingerPrint=$(ssh-keygen -lf $localPubKeyFileName | awk '!/is not a public key file/{print$2}')
	localPubKey=$(<$localPubKeyFileName)
}

initKeys $firstServer

function deployPubKeys {
	eval $(funcname) >&2
	if env | grep -q remoteServerType
	then
		echo "=> remoteServerType = $remoteServerType"
	else
		printf "=> What is the remote server type [AIX/Solaris/HP-UX/Linux] ? "
		read remoteServerType
	fi

	remoteServerType=$(echo "$remoteServerType" | tr [:upper:] [:lower:])
	case $remoteServerType in
		aix|solaris|hp-ux) remotePubKeyFileBasename=$USER.pub;;
		linux)			 remotePubKeyFileBasename=authorized_keys;;
		*) echo "=> ERROR: Unknown OS type." >&2 && clean_exit 4 ;;
	esac
	remotePubKeyFilename=$sshKeysDir/$remotePubKeyFileBasename
	echo

env | grep -q DEBUG && set -x

	tmpFile=$(mktemp)
	printf "=> Please enter your password: "
	stty -echo;read pass;stty echo
	echo $pass > $tmpFile
	chmod 600 $tmpFile
	unset pass

	for remoteServer
	do
		echo "=> Testing the ssh route to <$remoteServer> ..."
		if $(which bash) -c ": < /dev/tcp/$remoteServer/ssh"
		then
			echo "=> Checking your remote public key on <$remoteServer> ..."
#			remotePubKeyFingerPrint=$(ssh -q $remoteServer 2>/dev/null "
			sshpass -f $tmpFile ssh -q $remoteServer echo
			if [ $? != 0 ]
			then
				echo "=> ERROR: Your password is wrong." >&2
				clean_exit 3
			fi
			sshpass -f $tmpFile ssh -q $remoteServer 2>/dev/null "
				chmod go-w .
				test -d $sshKeysDir && chmod 700 $sshKeysDir || mkdir -pm 700 $sshKeysDir
				if [ -s $remotePubKeyFilename ]
				then
					fingerPrint=\$(ssh-keygen -lf $remotePubKeyFilename | awk '!/is not a public key file/{print\$2}')
					echo \$fingerPrint
				fi

				if [ $localPubKeyFingerPrint != \"\$fingerPrint\" ]
				then
					echo '=> Updating your public key on <$remoteServer> ...'
					echo $localPubKey >> $remotePubKeyFilename
				else
					echo '=> Your public key is already here on remote server: <$remoteServer>.'
				fi
				chmod 600 $remotePubKeyFilename
"

		else
			echo "=> WARNING: The ssh route to <$remoteServer> is not opened, switching to next ..." >&2
		fi
	done
	rm $tmpFile
	echo
	echo "=> END of the function: deployPubKeys."
}

deployPubKeys $@

if [ $privateKeyFileName ]
then
	if [ -s $privateKeyFileName ]
	then
		echo
		echo "=> Don't forget to download your ssh private key file : $privateKeyFileName to your Desktop for PuTTY to use."
		test $privateKeyFileName = $HOME/$sshKeysDir/$USER.ppk || {
			echo "=> This key is a OpenSSH private key, you have to import and convert to SSH2/SSH.com format using PuTTYGen before using it."
		}
	else
		echo "=> ERROR: Your private key file <$privateKeyFileName> doest not exist or is empty." >&2
		clean_exit 1
	fi
	echo
fi

#grep -q ssh-agent $HOME/.profile || {
#	echo echo "=> Loading the SSH authentication agent ..."
#	echo 'ps -fu $USER | grep -v grep | grep -q ssh-agent || eval $(ssh-agent -s)'
#} >> $HOME/.profile

#ps -fu $USER | grep -v grep | grep -q ssh-agent || eval $(ssh-agent -s)
#ssh-add $HOME/$sshKeysDir/$localPubKeyFilePrefix

clean_exit $?
