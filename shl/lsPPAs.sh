#!/usr/bin/env bash

function lsPPAs {
	local releaseCodeName=$(lsb_release -sc 2>/dev/null)
	local sourcesDisabledFileList=$({ cd /etc/apt/sources.list.d/;grep "^\s*Enabled:.no" *-$releaseCodeName.sources -l || echo '^$'; } | paste -sd"|" -;)
	local sourcesEnabledFileList=$(ls /etc/apt/sources.list.d/*-$releaseCodeName.sources | egrep -v "$sourcesDisabledFileList")
	awk -F "[ /]" 'BEGINFILE{if(ERRNO)nextfile}
		$0 ~ /^(deb|URIs:) .*launchpad.*.net/ {
		print"https://launchpad.net/~"$5"/+archive/ubuntu/"$6" ppa:"$5"/"$6
}' /etc/apt/sources.list.d/*-$releaseCodeName.list $sourcesEnabledFileList 2>/dev/null | sort -u
}

lsPPAs
