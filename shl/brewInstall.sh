#!/usr/bin/env sh

case $(uname) in 
	Darwin)
		command -v brew >/dev/null || $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		set -x;$(which brew) tap caskroom/cask;set +x ;;
	Linux)
		command -v brew >/dev/null || $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)" ;;
	*) echo "=> ERROR : brew does not support $(uname)." >&2; exit 1;;
esac
