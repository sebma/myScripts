#!/usr/bin/env bash

function lsNonPPAs {
	awk -F "[ /]" 'BEGINFILE{if(ERRNO)nextfile}
	/launchpad.*.net|esm.ubuntu.com|^#|^\s*$/{next}
	{sub("^.*https?","https")}
	/\s#/{print$1" # "$NF} !/\s#/{print$1}' /etc/apt/sources.list.d/*.list 2>/dev/null | sort -u
}

lsNonPPAs
