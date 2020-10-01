#!/usr/bin/env sh

brewPostInstall ()
{
	brew=$(which brew)
	echo "=> Updating homebrew ..." 1>&2
	echo 1>&2
	time $brew update -v || return
	echo 1>&2
	echo "=> Adding missing taps ..." 1>&2
	echo 1>&2
	time for tap in homebrew/core homebrew/services homebrew/cask homebrew/cask-versions homebrew/cask-drivers homebrew/cask-fonts buo/cask-upgrade
	do
		$brew tap | \grep -q $tap || {
			set -x
			time $brew tap $tap
			set +x
		}
	done
}

brewPostInstall
