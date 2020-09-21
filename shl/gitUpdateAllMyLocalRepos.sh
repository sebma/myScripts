#!/usr/bin/env bash

gitUpdateAllMyLocalRepos ()
{
	local find="$(which find)"
	echo $OSTYPE | grep --color=auto -q android && local osFamily=Android || local osFamily=$(uname -s)
	[ $osFamily = Darwin ] && find=gfind
	local dir=""
	$find ~ -maxdepth 2 -type d -name .git | while read dir; do
		cd $dir/..
		echo "=> Updating <$dir> local repo. ..." 1>&2
		\grep -w "^[[:blank:]]url" ./.git/config
		\git pull
		cd - > /dev/null
	done
	unset dir
}

gitUpdateAllMyLocalRepos
