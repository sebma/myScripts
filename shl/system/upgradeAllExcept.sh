#!/usr/bin/env bash

function upgradeAllBut {
	local packagesNotUpgraded="$@"
	local apt="command apt"
	local retCode=-1
	if [ -z "$packagesNotUpgraded" ]
	then
		packagesToBeUpgraded=$($(which apt-get) dist-upgrade --dry-run | awk '/^Inst/{print$2}' | grep -v "Listing..." | xargs)
	else
		packagesNotUpgraded=$(echo $packagesNotUpgraded | tr ' ' '|')
		packagesToBeUpgraded=$($(which apt-get) dist-upgrade --dry-run | awk '/^Inst/{print$2}' | egrep -v "$packagesNotUpgraded" | grep -v "Listing..." | xargs)
	fi

	echo "=> packagesToBeUpgraded = <$packagesToBeUpgraded>"
	echo
	if test -n "$packagesToBeUpgraded";then
		if [ -n "$SSH_CONNECTION" ] && which screen >/dev/null 2>&1;then
			sudo screen -L $apt install -V $packagesToBeUpgraded
		else
			sudo $apt install -V $packagesToBeUpgraded
		fi
	fi
	retCode=$?
	sync
	return $retCode
}
function main {
	set -- ${@%/*}  # Remove trailing "/distrib" from all arguments
	local os=$(uname -s)
	if [ $os = Linux ]
	then
		if [ -e /etc/debian_version ]; then	
			upgradeAllBut "$@"
			return $?
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
