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
	osFamily=undefined
	$(which bash) -c 'echo $OSTYPE' | grep -q android && osFamily=Android || osFamily=$(uname -s)
	if ! which brew > /dev/null 2>&1; then
		if [ $osFamily = Linux ]; then
			if groups | \egrep -wq "adm|admin|sudo|wheel"; then
				$SHELL -c "$(\curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || return
				brewPrefix=/home/linuxbrew/.linuxbrew
			else
				git --help >/dev/null || return
				brewPrefix=$HOME/brew
				cd $brewPrefix
				git clone https://github.com/homebrew/brew
#				time git clone https://github.com/homebrew/homebrew-core ./Library/Taps/homebrew/homebrew-core
				time $brewPrefix/bin/brew tab homebrew/core
				cd - >/dev/null
			fi
		elif [ $osFamily = Darwin ]; then
			$SHELL -c "$(\curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || return
			brewPrefix=/usr/local
		fi

		addpaths $brewPrefix
		brew=$brewPrefix/bin/brew
		$brew -v
	fi

	$scriptDir/brewPostInstall.sh
	sync
}

brewInstall "$@"
