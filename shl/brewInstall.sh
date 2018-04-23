#!/usr/bin/env sh

brew=$(which brew)
case $(uname) in 
	Darwin)
		test -z $brew && $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		brew=$(which brew) || exit 1
		set -x
		$brew update
#		$brew tap homebrew/versions # deprecated : See https://docs.brew.sh/Versions.html
		$brew tap caskroom/versions
		$brew tap caskroom/cask
		$brew tap caskroom/drivers
		$brew tap buo/cask-upgrade
		set +x ;;
	Linux)
		test -z $brew && $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
		brew=$(which brew) || exit 1
		$brew update ;;
	*) echo "=> ERROR : brew does not support <$(uname)> operating system." >&2; exit 1;;
esac
