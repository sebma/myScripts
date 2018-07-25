#!/usr/bin/env sh

brew=$(which brew)
case $(uname) in 
	Darwin)
		brewName=Homebrew
		if ! which brew > /dev/null 2>&1; then
			if groups | grep --color -E -wq "adm|admin|sudo"; then
				$(which ruby) -e "$(\curl -fsSL https://raw.githubusercontent.com/$brewName/install/master/install)" ||  return
				brew=/usr/local/bin/brew
			else
				brewPrefix=$HOME/homebrew
				\mkdir -pv -p $brewPrefix && \curl -L https://github.com/Homebrew/brew/tarball/master | \tar xz --strip 1 -C $brewPrefix || return
				brew=$brewPrefix/bin/brew
			fi
		fi
		set -x
		$brew update
		$brew tap caskroom/cask
		$brew tap caskroom/drivers
		$brew tap caskroom/versions
		$brew tap buo/cask-upgrade
		set +x
	Linux)
		brewName=Linuxbrew
		test -z $brew && $(which ruby) -e "$(\curl -fsSL https://raw.githubusercontent.com/$brewName/install/master/install)"
		brew=$(which brew) || exit 1
		$brew update ;;
	*) echo "=> ERROR : brew does not support <$(uname)> operating system." >&2; exit 1;;
esac
