#!/usr/bin/env bash

gitUpdateAllMyLocalRepos ()
{
	local find="command find"
	local remoteRepoUrl=""

	if ! type -P git >/dev/null;then
		echo "=> $FUNCNAME: ERROR : You must first install git." >&2
		return 1
	fi

	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s) # The bash interpreter is needed for it sets the OSTYPE variable
	[ $osFamily = Darwin ] && find=gfind
	local dir=""
	$find ~ -maxdepth 2 -type d -name .git 2>/dev/null | \egrep -v "/.linuxbrew/" | sort | while read dir; do
		cd $dir/..
		remoteRepoUrl=$(git config --local remote.origin.url)
		test -n "$remoteRepoUrl" && echo "=> Updating <$dir> repo. from <$remoteRepoUrl> repo. ..." 1>&2 && git pull && sync
		cd - > /dev/null
		echo
	done
}

gitUpdateAllMyLocalRepos
