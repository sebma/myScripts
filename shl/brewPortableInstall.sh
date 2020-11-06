#!/usr/bin/env sh

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)

brewPortableInstall ()
{
	brew=undefined
	brewPrefix=undefined
	osFamily=undefined
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
	$(which bash) -c 'echo $OSTYPE' | grep -q android && osFamily=Android || osFamily=$(uname -s)
	if ! which brew > /dev/null 2>&1; then
		git --help >/dev/null || return
		brewPrefix=$HOME/.linuxbrew
		git clone https://github.com/homebrew/brew $brewPrefix
		bash -c "time $brewPrefix/bin/brew tab homebrew/core"

		echo $PATH | grep -q $brewPrefix || export PATH=$brewPrefix/bin:$PATH
		brew=$brewPrefix/bin/brew
		$brew -v
	fi

	$scriptDir/brewPostInstall.sh
}

brewPortableInstall "$@"
