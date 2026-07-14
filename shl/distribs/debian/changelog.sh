#!/usr/bin/env bash

set -- ${@%/*}  # Remove trailing "/distrib" from all arguments
for package
do
	if apt-get changelog $package &>/dev/null
	then
		apt-get changelog $package
	else
		ppa_user_name=$(apt-cache policy $package | grep -m1 500.http | awk -F/ '{print$4}')
		ppa_name=$(apt-cache policy $package | grep -m1 500.http | awk -F/ '{print$5}' | awk '{print$NF}')
		package_version=$(LANG=C apt-cache policy $package | awk -F"[ :]" '/Candidate:/{print$NF}')
		URL=https://launchpad.net/~$ppa_user_name/+archive/ubuntu/$ppa_name/+files/${package}_${package_version}_source.changes
		#echo "=> URL = $URL"
		grep -q launchpad.net <<< "$URL" || { echo "=> ERROR: The package is not installed from <launchpad.net>" >&2 ; exit 1; }
		set -x
		\curl -qLs $URL | awk '/Changes:/{f=1;next}/Checksums/{f=0}f'
	fi
done
