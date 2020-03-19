#!/usr/bin/env sh

brew=$(which brew)
homeBrewInstallerURL=https://raw.githubusercontent.com/Homebrew/install/master/install.sh
portableHomeBrewURL=https://github.com/Homebrew/brew
case $(uname) in 
	Darwin)
		if ! which brew > /dev/null 2>&1; then
			if groups | grep --color -E -wq "adm|admin|sudo"; then
				test -z $brew && bash -c "$(\curl -fsSL $homeBrewInstallerURL)" || return
				brewPrefix=/usr/local
			else
				brewPrefix=$HOME/homebrew
				# cf. https://docs.brew.sh/Installation#untar-anywhere
				#\mkdir -pv -p $brewPrefix && \curl -L https://github.com/Homebrew/brew/tarball/master | \tar xz --strip 1 -C $brewPrefix || return
				git clone $portableHomeBrewURL $brewPrefix # cf. https://stackoverflow.com/a/55021458/5649639
			fi
			brew=$brewPrefix/bin/brew
		fi
		set -x
		$brew update
		$brew tap caskroom/cask
		$brew tap caskroom/drivers
		$brew tap caskroom/versions
		$brew tap buo/cask-upgrade
		set +x
		;;
	Linux)
		if ! which brew > /dev/null 2>&1; then
			if groups | grep --color -E -wq "adm|admin|sudo"; then
				test -z $brew && bash -c "$(\curl -fsSL $homeBrewInstallerURL)" || return
				brewPrefix=/home/linuxbrew/.linuxbrew
			else
				# cf. https://docs.brew.sh/Homebrew-on-Linux#alternative-installation
				brewPrefix=$HOME/.linuxbrew/
				git clone $portableHomeBrewURL $brewPrefix/Homebrew
				\mkdir -pv $brewPrefix/bin
				\ln -vs $brewPrefix/Homebrew/bin/brew $brewPrefix/bin/brew
				eval $($brewPrefix/bin/brew shellenv)
			fi
			brew=$brewPrefix/bin/brew
		fi
		$brew update ;;
	*) echo "=> ERROR : brew does not support <$(uname)> operating system." >&2; exit 1;;
esac
