#!/usr/bin/env bash4


function main {
	set -o nounset
	! declare -p | grep -wq color= && test -r ~/.initBash/.colors && source ~/.initBash/.colors
	
	echo "$bold${color[red]}=> INFO: Starting <$(basename $0)>...$normal"

	#SOURCES
	local dirList="$(echo ~/{Documents,Downloads,Pictures,log,shl,local,usr/local/bin,.initBash})"
	local sailFishDirList="$(echo ~/{.config,.gconf,.local})"
	local otherSFDatabesDirList="$(echo ~/{.ipython,.qmf})"
	local androidDirList="$(echo ~/android_storage/{DCIM,mysword,.youversion})"
	local bigMultimediaFilesDirList="$(echo ~/{Videos,Recordings})"
	local androidAPKsDirList="$(echo {/data/app,})"
	local linuxBrewDirList=~/.linuxbrew
	
	local extSDCard="$(df | awk '/ .media.sdcard/{print$NF}')"
	if test "$extSDCard"
	then
		#DESTINATIONS
		local dataDestinationRoot=$extSDCard/jolla

		local dataDestination=$dataDestinationRoot/home/nemo
		local androidBackupDir=$dataDestinationRoot/home/nemo/android_storage
		local androidAppsDestination=$dataDestinationRoot/data

		local syncCommand="rsync -vuth -P -m -r"
		echo "=> syncCommand = $syncCommand"
		echo
		echo "$bold${color[blue]}=> Backing up Android apks to <$androidBackupDir/.aptoide/> ...$normal"
		if mount | grep -q /android_storage
		then
			time $syncCommand --size-only ~/android_storage/.aptoide/apks $androidBackupDir/.aptoide/ ; echo
			echo "$bold${color[blue]}=> Backing up Android $androidDirList to <$androidBackupDir/> ...$normal" && time $syncCommand --size-only --exclude ".thumbdata*" --exclude "Pictures/Jolla/*" --exclude "*/mail_attachments/*" $androidDirList $androidBackupDir/ ; echo
		else
			echo "$bold${color[red]}=> INFO: android_storage is not mounted yet.$normal" >&2 ; echo
		fi
	
		echo "$bold${color[blue]}=> Backing up Jolla's $dirList to <$dataDestination/> ...$normal" && time $syncCommand --size-only --exclude ".thumbdata*" --exclude "Pictures/Jolla/*" --exclude "*/mail_attachments/*" $dirList $dataDestination/ && echo
		echo "$bold${color[blue]}=> Backing up Jolla's $sailFishDirList to <$dataDestination/> ...$normal" && time $syncCommand $sailFishDirList $dataDestination/ ; echo
		echo "$bold${color[blue]}=> Backing up Jolla's $otherSFDatabesDirList to <$dataDestination/> ...$normal" && time $syncCommand --include "*/" --include "*.db*" --include "*.sqlite" --include "*.ini" --include "*.conf" --exclude="*" $otherSFDatabesDirList $dataDestination/ && echo
		echo "$bold${color[blue]}=> Moving Jolla's $bigMultimediaFilesDirList to <$dataDestination/> ...$normal" && time $syncCommand --size-only --remove-source-files $bigMultimediaFilesDirList $dataDestination/ && echo
		echo "$bold${color[blue]}=> Backing up Jolla's $androidAPKsDirList to <$androidAppsDestination/> ...$normal" && time $syncCommand --size-only $androidAPKsDirList $androidAppsDestination/ && echo
		echo "$bold${color[blue]}=> Backing up Jolla's $linuxBrewDirList to <$dataDestination/> ...$normal" && time $syncCommand --size-only --exclude ".git" $linuxBrewDirList $dataDestination/ | egrep -v "skipping non-regular file" && echo
		sync
	else
		echo "$bold${color[red]}=> ERROR: The SD card is not mounted yet, please wait and relaunch <$(basename $0)>.$normal" >&2
		exit 1
	fi

	set +x
	echo "$bold${color[blue]}=> DONE.$normal"
}

main $@

exit
