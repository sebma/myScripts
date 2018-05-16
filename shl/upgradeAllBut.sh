#!/usr/bin/env bash

function upgradeAllBut {
	local packagesNotUpgraded="$@"
	packagesNotUpgraded=$(echo $packagesNotUpgraded | tr ' ' '|')
#	packagesToBeUpgraded=$($(which apt) list --upgradable 2>/dev/null | cut -d/ -f1 | egrep -v "$packagesNotUpgraded" | grep -v "Listing...")
	packagesToBeUpgraded=$($(which apt-get) upgrade --dry-run | awk '/^Inst/{print$2}' | egrep -v "$packagesNotUpgraded" | grep -v "Listing...")
	echo "=> packagesToBeUpgraded = <$packagesToBeUpgraded>"
	set -x
	sudo apt install -V $packagesToBeUpgraded
	set +x
}

function main {
	local os=$(uname -s)
	if [ $os = Linux ]
	then
		if [ -e /etc/debian_version ]; then	
			upgradeAllBut "$@"
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
