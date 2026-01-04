#!/usr/bin/env bash

function lsNonPPAs {
	local releaseCodeName=$(lsb_release -sc 2>/dev/null)
	local sourcesDisabledFileList=$({ cd /etc/apt/sources.list.d/;grep "^\s*Enabled:.no" *-$releaseCodeName.sources -l || echo '^$'; } | paste -sd"|" -;)
	local sourcesEnabledFileList=$(ls /etc/apt/sources.list.d/*-$releaseCodeName.sources | egrep -v "$sourcesDisabledFileList")
	awk -F "[ /]" 'BEGINFILE{if(ERRNO)nextfile}
	/launchpad.*.net|esm.ubuntu.com|^#|^\s*$/{next}
	{sub("^.*https?","https")}
	/\s#/{print$1" # "$NF} !/\s#/{print$1}' /etc/apt/sources.list.d/*.list 2>/dev/null | sort -u
}

lsNonPPAs
