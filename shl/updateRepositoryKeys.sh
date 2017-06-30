#!/bin/bash

function updateRepositoryKeys {
	pubkeyList="$(sudo apt-get update 2>&1 > /dev/null | awk '/PUBKEY/{print $NF}')"
	echo "=> pubkeyList = $pubkeyList"
	for key in $pubkeyList
	do
		sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $key
		echo "=> CodeRet=$?"
	done

	apt-get update > /dev/null
}

updateRepositoryKeys
