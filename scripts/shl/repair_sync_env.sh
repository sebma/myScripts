#!/usr/bin/env ksh

trap 'echo "=> Couché !' INT

function initColors {
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

function clean_exit {
	if test $1
	then
		RepositoryMountPoint=$1
	else
		return 0
	fi
	if test $RepositoryMountPoint
	then
		echo "=> Trying to unmount <$RepositoryMountPoint> ..."
		if fusermount -u $RepositoryMountPoint 2>&1 | grep failed.*busy
		then
			echo
			echo "=> Could not unmount <$RepositoryMountPoint>, killing all process working on <$RepositoryMountPoint> ..."
			pgrep -lfu $USER $RepositoryMountPoint && pkill -USR1 -fu $USER $RepositoryMountPoint
			echo
			echo "=> Re-trying to unmount the sshfs <$RepositoryMountPoint> ..."
			sleep 1
			cd $(dirname $RepositoryMountPoint)
			if fusermount -u $RepositoryMountPoint
			then
				echo "=> The sshfs <$whiteOnBlue$RepositoryMountPoint$normal> was unmounted successfully."
				rmdir -v $RepositoryMountPoint
				true
			else
				rc=$?
				echo "=> ERROR: Could not unmout <$blink$yellowOnRed$RepositoryMountPoint$normal>." >&2
				exit $?
			fi
		fi
	else
		echo "==> There is no source sshfs mounted for <$USER> in <$HOME>."
	fi

	echo $normal
	echo "=> FIN de la fonction <clean_exit> de nettoyage qui permettra de relancer le programme <sync_env>."
}

function main {
	initColors
	echo "=> Lancement du script <$progBaseName> de nettoyage qui permettra de relancer le programme <sync_env>."
	echo
	echo "==> Killing the remaining <sync_env> processes if any ..."
	pgrep -lfu $USER "\<sync_env" && echo && pkill -fu $USER "\<sync_env" && sleep 1
	rm -vf /var/log/sync_env/sync_env*.pipe && echo

	sourceRepositoryMountPoint=$(mount | awk /source.*sshfs.*$USER/'{print$3}')
	destRepositoryMountPoint=$(mount | awk '!/source/&&'/sshfs.*$USER/'{print$3}')
	clean_exit $sourceRepositoryMountPoint
	clean_exit $destRepositoryMountPoint
}

progBaseName=$(basename $0)
main

