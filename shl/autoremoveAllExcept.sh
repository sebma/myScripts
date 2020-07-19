#!/usr/bin/env bash

function autoremoveAllBut {
	local packagesNotUpgraded="$@"
	local apt=$(which apt)
	if [ -z "$packagesNotUpgraded" ]
	then
		packagesToBeRemoved=$($(which apt-get) autoremove --dry-run | awk '/^Remv/{print$2}' | grep -v "Listing..." | xargs)
	else
		packagesNotUpgraded=$(echo $packagesNotUpgraded | tr ' ' '|')
		packagesToBeRemoved=$($(which apt-get) autoremove --dry-run | awk '/^Remv/{print$2}' | egrep -v "$packagesNotUpgraded" | grep -v "Listing..." | xargs)
	fi

	echo "=> packagesToBeRemoved = <$packagesToBeRemoved>"
	echo
	test -n "$packagesToBeRemoved" && sudo screen -L $apt purge -V $packagesToBeRemoved
	sync
	set +x
}

function main {
	set -- ${@%/*}  # Remove trailing "/distrib" from all arguments
	local os=$(uname -s)
	if [ $os = Linux ]
	then
		if [ -e /etc/debian_version ]; then	
			autoremoveAllBut "$@"
		else
			echo "=> The distribution $(\lsb_release -si) is not supported." >&2
			return 1
		fi
	else
		echo "=> $os is not supported." >&2
		return 2
	fi
}

main "$@"
