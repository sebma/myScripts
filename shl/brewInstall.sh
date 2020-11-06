#!/usr/bin/env sh

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)

brewInstall () {
	brew=undefined
	brewPrefix=undefined
	osFamily=undefined
	$(which bash) -c 'echo $OSTYPE' | grep -q android && osFamily=Android || osFamily=$(uname -s)
	if ! which brew > /dev/null 2>&1; then
		if [ $osFamily = Linux ]; then
			if groups | \egrep -wq "adm|admin|sudo|wheel"; then
				brewPrefix=/home/linuxbrew/.linuxbrew
			else
				brewPrefix=$HOME/.linuxbrew
			fi
		elif [ $osFamily = Darwin ]; then
			brewPrefix=/usr/local
		fi

		$SHELL -c "$(\curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || return

		echo $PATH | grep -q $brewPrefix || export PATH=$brewPrefix/bin:$PATH
		brew=$brewPrefix/bin/brew
		$brew -v
	fi

	$scriptDir/brewPostInstall.sh
}

brewInstall "$@"
