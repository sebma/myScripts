#!/usr/bin/env bash

gitUpdateAllMyLocalRepos ()
{
	local find="$(which find)"
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)
	[ $osFamily = Darwin ] && find=gfind
	local dir=""
	$find ~ -maxdepth 2 -type d -name .git | while read dir; do
		cd $dir/..
		echo "=> Updating <$dir> local repo. ..." 1>&2
		git config --local remote.origin.url
		git pull
		cd - > /dev/null
		echo
	done
	unset dir
}

gitUpdateAllMyLocalRepos
