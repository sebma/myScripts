#!/usr/bin/env bash4

set -o nounset

function main {
	if [ $# != 0 ] && [ "$1" = "-h" ]
	then 
		echo "=> INFO Usage: $(basename $0) remoteUser@remoteServer:remotePath" >&2
		return 1
	fi

	if test $# != 0 
	then
		echo $1 | grep -q : || {
			echo "=> ERROR : $(basename $0) <$1> is not a valid destination, it must contain a ':'." >&2
			return 2
		}
		local remotePC=$(echo $1 | sed "s/^.*@\|:.*$//g" )
		echo $1 | grep -q ":$" && local dataDestinationRoot=${1}jolla || local dataDestinationRoot=$1/jolla
	else	
		local myPC=192.168.0.11
		local remotePC=$myPC
		local dataDestinationRoot=sebastien@$remotePC:jolla
	fi

	#SOURCES
	local dirList="$(echo ~/{Documents,Downloads,Pictures,log,shl,local,usr/local/bin,.initBash})"
	local sailFishDirList="$(echo ~/{.config,.gconf,.local})"
	local otherSFDatabesDirList="$(echo ~/{.ipython,.qmf})"
	local androidDirList="$(echo ~/android_storage/{DCIM,mysword,.youversion})"
	local bigMultimediaFilesDirList="$(echo ~/{Videos,Recordings})"
	local androidAPKsDirList="$(echo {/data/app,})"
	local linuxBrewDirList=~/.linuxbrew
	
	#DESTINATIONS
	local dataDestination=$dataDestinationRoot/home/nemo
	local androidBackupDir=$dataDestinationRoot/home/nemo/android_storage
	local androidAppsDestination=$dataDestinationRoot/data

	! declare -p | grep -wq color= && test -r ~/.initBash/.colors && source ~/.initBash/.colors

	echo "$bold${color[red]}=> INFO: Starting <$(basename $0)>...$normal"

	#if $(which netcat) -v -z -w 5 $remotePC ssh
	if time $(which bash) -c ": < /dev/tcp/$remotePC/ssh"
	then
		local syncCommand="rsync -vuth -P -m -rl"
		echo "=> syncCommand = $syncCommand"
		echo
		echo "$bold${color[blue]}=> Backing up Android apks to <$androidBackupDir/.aptoide/> ...$normal"
		if mount | grep -q /android_storage
		then
			time $syncCommand ~/android_storage/.aptoide/apks $androidBackupDir/.aptoide/ ; echo
			echo "$bold${color[blue]}=> Backing up Android $androidDirList to <$androidBackupDir/> ...$normal" && time $syncCommand --exclude ".thumbdata*" --exclude "Pictures/Jolla/*" --exclude "*/mail_attachments/*" $androidDirList $androidBackupDir/ ; echo
		else
			echo "$bold${color[red]}=> INFO: android_storage is not mounted yet.$normal" >&2 ; echo
		fi
	
		echo "$bold${color[blue]}=> Backing up Jolla's $dirList to <$dataDestination/> ...$normal" && time $syncCommand --exclude ".thumbdata*" --exclude "Pictures/Jolla/*" --exclude "*/mail_attachments/*" $dirList $dataDestination/ && echo
		echo "$bold${color[blue]}=> Backing up Jolla's $sailFishDirList to <$dataDestination/> ...$normal" && time $syncCommand $sailFishDirList $dataDestination/ ; echo
		echo "$bold${color[blue]}=> Backing up Jolla's $otherSFDatabesDirList to <$dataDestination/> ...$normal" && time $syncCommand --include "*/" --include "*.db*" --include "*.sqlite" --include "*.ini" --include "*.conf" --exclude="*" $otherSFDatabesDirList $dataDestination/ && echo
		echo "$bold${color[blue]}=> Backing up Jolla's $bigMultimediaFilesDirList to <$dataDestination/> ...$normal" && time $syncCommand --exclude "Videos/Jolla/*" $bigMultimediaFilesDirList $dataDestination/ && echo
		echo "$bold${color[blue]}=> Backing up Jolla's $androidAPKsDirList to <$androidAppsDestination/> ...$normal" && time $syncCommand $androidAPKsDirList $androidAppsDestination/ && echo
		echo "$bold${color[blue]}=> Backing up Jolla's $linuxBrewDirList to <$dataDestination/> ...$normal" && time $syncCommand --exclude ".git" $linuxBrewDirList $dataDestination/ && echo
		sync
	else
		echo "$bold${color[red]}=> ERROR: The ssh dataDestination <$remotePC> is not reachable." >&2
		return 3
	fi
	echo "$bold${color[blue]}=> DONE.$normal"
	set +x
}

main $@

exit
