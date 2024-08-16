#!/usr/bin/env bash

function snapRemoteAllDisabledPackages {
	snap list --all | awk "/disabled/"'{print $1" "$3}' | while read package revision;do
		echo "=> sudo snap remove $package --revision=$revision ..."
		sudo snap remove $package --revision=$revision
	done
}

snapRemoteAllDisabledPackages
