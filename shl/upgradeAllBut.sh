#!/usr/bin/env bash

function upgradeAllBut {
	local packagesNotUpgraded="$@"
	if [ -z $packagesNotUpgraded ]
	then
		packagesToBeUpgraded=$($(which apt-get) dist-upgrade --dry-run | awk '/^Inst/{printf$2" "}' | grep -v "Listing...")
	else
		packagesNotUpgraded=$(echo $packagesNotUpgraded | tr ' ' '|')
		packagesToBeUpgraded=$($(which apt-get) dist-upgrade --dry-run | awk '/^Inst/{print$2" "}' | egrep -v "$packagesNotUpgraded" | grep -v "Listing...")
	fi

	echo "=> packagesToBeUpgraded = <$packagesToBeUpgraded>"
	echo
	test -n "$packagesToBeUpgraded" && sudo apt install -V $packagesToBeUpgraded
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
