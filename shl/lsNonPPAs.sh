#!/usr/bin/env bash

function lsNonPPAs {
	releaseCodeName=$(lsb_release -sc 2>/dev/null)
	awk -F "[ /]" 'BEGINFILE{if(ERRNO)nextfile}
	/launchpad.*.net|esm.ubuntu.com|^#|^\s*$/{next}
	{sub("^.*https?","https")}
	/\s#/{print$1" # "$NF} !/\s#/{print$1}' /etc/apt/sources.list.d/*-$releaseCodeName.list 2>/dev/null | sort -u
}

lsNonPPAs
