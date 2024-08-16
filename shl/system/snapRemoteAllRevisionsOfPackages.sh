#!/usr/bin/env bash

function snapRemoteAllRevisionsOfPackages {
	for packageRegExp
	do
		snap list --all | awk "/$packageRegExp/"'{print $1" "$3}' | while read package revision;do
			echo "=> sudo snap remove $package --revision=$revision ..."
			sudo snap remove $package --revision=$revision
		done
	done
}

snapRemoteAllRevisionsOfPackages "$@"
