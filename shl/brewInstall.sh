#!/usr/bin/env sh

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)

addpaths ()
{
	for path in "$@"
	do
		test ! -d "$path" && continue
		echo $PATH | \grep -wq "$path" || PATH=$path:$PATH
	done
	export PATH
}

brewInstall ()
{
	brew=undefined
	brewPrefix=undefined
	if ! which brew > /dev/null 2>&1; then
		if groups | \egrep -wq "adm|admin|sudo|wheel"; then
			$(which bash) -c "$(\curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || return
			addpaths /home/linuxbrew/.linuxbrew/bin
			brew=$(which brew)
		else
			brewPrefix=$HOME/brew
			git clone https://github.com/homebrew/brew $brewPrefix
			time git clone https://github.com/homebrew/homebrew-core $brewPrefix/Library/Taps/Homebrew/homebrew-core
			brew=$brewPrefix/bin/brew
		fi
	fi

	$scriptDir/brewPostInstall.sh
	sync
}

brewInstall "$@"
