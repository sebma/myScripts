#!/usr/bin/env bash

function lsPPAs {
	releaseCodeName=$(lsb_release -sc 2>/dev/null)
	awk -F "[ /]" 'BEGINFILE{if(ERRNO)nextfile}
	/^(deb|URIs:) .*launchpad.*.net/{
	print"https://launchpad.net/~"$5"/+archive/ubuntu/"$6" ppa:"$5"/"$6
}' /etc/apt/sources.list.d/*-$releaseCodeName.list /etc/apt/sources.list.d/*-$releaseCodeName.sources 2>/dev/null | sort -u
}

lsPPAs
