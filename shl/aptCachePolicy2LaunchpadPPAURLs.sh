#!/usr/bin/env bash

aptCachePolicy2LaunchpadPPAURLs ()
{
	local platform=$(uname -m)
	local arch=unset

	case $platform in
		x86_64)arch=amd64;;
		i686) arch=i386;;
		*) arch=UNKNOWN;;
	esac

	for pkg
	do
		aptCachePolicyOutPut=$(apt-cache policy $pkg)
		if echo $aptCachePolicyOutPut | grep -q launchpad.net;then
			printf "$pkg "
			echo "$aptCachePolicyOutPut" | awk '/Installed:/{printf$2}'
			echo "$aptCachePolicyOutPut" | awk "/launchpad.net.*$arch Packages/"'{print$2;exit}' | awk -F/ 'BEGIN{OFS=FS}{printf " ppa:"$4"/"$5" ";sub("ppa.","",$3);$4="~"$4"/+archive";tmp=$5;$5=$6;$6=tmp;print}'
		fi
	done | column -t
}

aptCachePolicy2LaunchpadPPAURLs "$@"
