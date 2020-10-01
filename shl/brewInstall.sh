#!/usr/bin/env sh

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
			addpaths /usr/local/bin
			brew=$(which brew)
		else
			brewPrefix=$HOME/brew
			git clone https://github.com/Homebrew/brew $brewPrefix
			time git clone https://github.com/Homebrew/homebrew-core $brewPrefix/Library/Taps/homebrew/homebrew-core
			brew=$brewPrefix/bin/brew
		fi
	fi
	if test -x $brew; then
		source .bash_functions.brew
		brewPostInstall
	fi
	sync
}

brewInstall "$@"
