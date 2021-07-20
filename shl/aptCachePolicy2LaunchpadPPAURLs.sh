#!/usr/bin/env sh

aptCachePolicy2LaunchpadPPAURLs ()
{
	for pkg
	do
		\apt-cache -q0 policy $pkg | awk '/launchpad.net/{print$2}' | awk -v pkg=$pkg -F/ 'BEGIN{OFS=FS}{printf pkg" ppa:"$4"/"$5" ";sub("ppa.","",$3);$4="~"$4"/+archive";tmp=$5;$5=$6;$6=tmp;print}'
	done | uniq | column -t
}

aptCachePolicy2LaunchpadPPAURLs "$@"
