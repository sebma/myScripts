#!/usr/bin/env bash

function lsPPAs {
	releaseCodeName=$(lsb_release -sc 2>/dev/null)
	sourcesDisabledFileList=$(cd /etc/apt/sources.list.d/;grep Enabled:.no *-$releaseCodeName.sources -l | paste -sd"|" -)
	sourcesEnabledFileList=$(ls /etc/apt/sources.list.d/*-$releaseCodeName.sources | egrep -v "$sourcesDisabledFileList")
	awk -F "[ /]" 'BEGINFILE{if(ERRNO)nextfile}
		/^(deb|URIs:) .*launchpad.*.net/{
		print"https://launchpad.net/~"$5"/+archive/ubuntu/"$6" ppa:"$5"/"$6
}' /etc/apt/sources.list.d/*-$releaseCodeName.list $sourcesEnabledFileList 2>/dev/null | sort -u
}

lsPPAs
