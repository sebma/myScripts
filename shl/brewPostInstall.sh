#!/usr/bin/env bash

interpreter=$(ps -o args= $$ | awk '{print gensub("^/.*/","",1,$1)}')

if [ $interpreter = bash ] || [ $interpreter = zsh ] || [ $interpreter = sh ];then
	local=local
else
	local=typeset
fi

brewPostInstall ()
{
	type brew >/dev/null || return
	$local brew="command brew"
	echo "=> Updating homebrew ..." 1>&2
	echo 1>&2
	bash -c "time $brew update -v"
	sync
	echo 1>&2
	echo "=> Adding missing taps ..." 1>&2
	echo 1>&2

	for tap in homebrew/core homebrew/services homebrew/cask homebrew/cask-versions homebrew/cask-drivers homebrew/cask-fonts buo/cask-upgrade
	do
		$brew tap | \grep -q $tap || {
			set -x
			bash -c "time $brew tap $tap"
			sync
			set +x
		}
	done

	local macOS_EssentialPackages="iproute2mac"
	local common_EssentialPackages="awk grep gsed coreutils findutils"
	[ $osFamily = Darwin ] && $brew install $common_EssentialPackages $macOS_EssentialPackages
}

brewPostInstall
