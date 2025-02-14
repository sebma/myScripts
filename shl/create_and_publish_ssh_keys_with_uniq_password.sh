#!/usr/bin/env bash

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
	typeset rc=0
	test $1 && rc=$1
	echo "=> START of function <clean_exit> with the error code <$rc>." >&2
	umask 022
	test -f $tmpFile && rm $tmpFile
	echo "=> END of function <clean_exit>."
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
#	echo "=> Starting the script <$progBaseName> developped by Sebastien MANSFELD :-)"

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

	echo "=> You are <$USER>: $(awk -F":|," /$USER/'{print$5}' /etc/passwd)."
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
	mkdir -p $HOME/$sshKeysDir

	privateKeyFileName=""
	firstServer=$1
	if [ ! -s $localPubKeyFileName ]
	then
		echo "=> Downloading your pubkey from the first server: <$firstServer>, if it exists ..."
		if scp -p $firstServer:$sshKeysDir/$localPubKeyFileBasename $HOME/$sshKeysDir/
		then
			shift
		else
			echo "=> There is no pubkey <$firstServer>. " >&2
			if type puttygen >/dev/null 2>&1
			then
				privateKeyFileName=$HOME/$sshKeysDir/$USER.ppk
				echo "=> Generating a SSH2/"ssh.com" (PuTTY) RSA ssh key pair with puttygen, it lasts from 30sec to one minute ..."
				puttygen -q -t rsa -o $privateKeyFileName
				echo "=> Extracting the public key from the file $(basename $privateKeyFileName) and converting it to OpenSSH format ..."
				puttygen $privateKeyFileName -O public-openssh > $localPubKeyFileName
			else
				privateKeyFileName=$HOME/$sshKeysDir/$localPubKeyFilePrefix
				echo "=> The puttygen is not installed, generating a OpenSSH format ssh-key pair, it lasts from 30sec to one minute ..."
				echo "=> Creating your ssh-key pair <$privateKeyFileName> and <$privateKeyFileName.pub> on server <$(hostname)> ..."
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
		echo "=> The pubkey is already on <$(hostname)>."
	fi
	umask 022

	echo "=> Setting the correct rights for your ssh files ..."
	chmod -R go-rwx $HOME/$sshKeysDir
	localPubKeyFingerPrint=$(ssh-keygen -lf $localPubKeyFileName | awk '!/is not a public key file/{print$2}')
	localPubKey=$(<$localPubKeyFileName)
}

echo
initKeys $firstServer

function deployPubKeys {
	eval $(funcname) >&2
	tmpFile=$(mktemp)
	if ! type -P sshpass >/dev/null 2>&1
	then
		echo "=> ERROR: The <sshpass> tool is not installed on <$(hostname)>." >&2
		clean_exit 1
	fi

	if ! env | grep -q remoteServerType
	then
		if type -P whiptail >/dev/null 2>&1
		then
			remoteServerType=$(whiptail --title "Remote server type" --menu "What is the remote server type [AIX / Solaris / HP-UX / Linux] ? " 20 78 16 \
			"a)" "AIX Server" "s)" "Solaris Server" "h)" "HP-UX Server" "l)" "Linux Server" "q)" Quit 3>&2 2>&1 1>&3)
		else
			PS3="=> What is the remote server type [AIX / Solaris / HP-UX / Linux] ? "
			select remoteServerType in AIX Solaris HP-UX Linux Quit
			do
				if [ -z $remoteServerType ]
				then
					REPLY="" #Pour re-afficher le menu
				else
					break
				fi
			done
		fi
	fi

	remoteServerType=$(echo "$remoteServerType" | sed "s/)//" | tr [:upper:] [:lower:])
#	echo "=> remoteServerType = <$remoteServerType>."
	case $remoteServerType in
		aix|solaris|hp-ux|a|s|h) remotePubKeyFileBasename=$USER.pub;;
		linux|l) remotePubKeyFileBasename=authorized_keys;;
		quit|q) echo "=> Goodbye." && clean_exit 0;;
		*) echo "=> ERROR: Unknown OS type." >&2 && clean_exit 4 ;;
	esac

	remotePubKeyFilename=$sshKeysDir/$remotePubKeyFileBasename
	echo "=> remotePubKeyFilename = <$remotePubKeyFilename>."

	stty -echo;read pass?"=> Please enter your ssh password to access <$firstServer>: ";stty echo
	echo $pass > $tmpFile
	chmod 600 $tmpFile
	unset pass

	echo
	echo "=> Checking your credentials on <$firstServer> ..."
	sshpass -f $tmpFile ssh -q $firstServer echo

	rc=$?
	if [ $rc = 5 ]
	then
		echo "=> ERROR: Your password is wrong." >&2
		clean_exit $rc
	elif [ $rc != 0 ]
	then
		clean_exit $rc
	fi

	set +o nounset
	scriptToRunRemotely=/tmp/check_and_update_pubkey_$USER
	cat <<-EOF > $scriptToRunRemotely
		#!sh
		test $DEBUG && set -x
		chmod go-w .
		mkdir -p $sshKeysDir
		[ -s $remotePubKeyFilename ] && fingerPrint=\$(ssh-keygen -lf $remotePubKeyFilename | awk '!/is not a public key file/{print\$2}')
		if [ "$localPubKeyFingerPrint" != "\$fingerPrint" ]
		then
			printf '=> Updating your public key'
			echo '$localPubKey' >> $remotePubKeyFilename
		else
			printf '=> Your public key is already'
		fi
		chmod -R go-rwx $sshKeysDir
EOF
	set -o nounset

	for remoteServer
	do
		echo "=> Testing the ssh route to <$remoteServer> ..."
		if $(which bash) -c "< /dev/tcp/$remoteServer/ssh"
		then
			echo "=> Checking your remote public key on <$remoteServer> ..."
			sshpass -f $tmpFile ssh -q $remoteServer "$(<$scriptToRunRemotely)"
			echo " on remote server <$remoteServer>."
		else
			echo "=> WARNING: The ssh route to <$remoteServer> is not opened, switching to next ..." >&2
		fi
	done
	rm $tmpFile $scriptToRunRemotely
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
		echo "=> Please install the original full PuTTY package available on : <http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html>."
	else
		echo "=> ERROR: Your private key file <$privateKeyFileName> doest not exist or is empty." >&2
		clean_exit 1
	fi
	echo
fi

clean_exit $?
