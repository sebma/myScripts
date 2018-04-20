#!/usr/bin/env sh

case $(uname) in 
	Darwin)
		command -v brew >/dev/null || $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		set -x
		brew=$(which brew) || exit
		$brew update
		$brew tap caskroom/cask
		$brew tap caskroom/drivers
#		$brew tap homebrew/versions # deprecated : See https://docs.brew.sh/Versions.html
		$brew tap caskroom/versions # For "brew cask" packages
		$brew tap buo/cask-upgrade
		set +x ;;
	Linux)
		command -v brew >/dev/null || $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
		brew=$(which brew) || exit
		$brew update ;;
	*) echo "=> ERROR : brew does not support $(uname)." >&2; exit 1;;
esac
