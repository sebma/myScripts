#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)

TeXLiveInstall () {
	osFamily=undefined
	wget=wget
	command bash -c 'echo $OSTYPE' | grep -q android && osFamily=Android || osFamily=$(uname -s)
	if ! type -P tlmgr > /dev/null 2>&1; then
		if [ $osFamily = Linux ]; then
			$wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
			texLiveDIR=$(tar tf install-tl-unx.tar.gz | awk -F/ '/\/$/{print$(NF-1);exit}')
			texLiveFullVersion=$(tar tf install-tl-unx.tar.gz | awk -F"[/-]" '/\/$/{print$(NF-1);exit}')
			texLiveVersion=$(echo $texLiveFullVersion | cut -c -4)
			tar xzf install-tl-unx.tar.gz
			if cd $texLiveDIR;then
				if groups | \egrep -wq "adm|admin|sudo|root|wheel"; then
					time sudo ./install-tl -scheme scheme-small
					texlivePrefix=/usr/local/texlive/$texLiveVersion
					tlmgr=$texlivePrefix/bin/$arch-${osFamily,,}/tlmgr
				else
					time ./install-tl -scheme scheme-small
					texlivePrefix=$HOME/.texlive$texLiveVersion
					tlmgr="$texlivePrefix/bin/$arch-${osFamily,,}/tlmgr --usermode"
					$tlmgr init-usertree
				fi
				cd - >/dev/null
			fi
			rm -fr install-tl-unx.tar.gz ./$texLiveDIR/
		elif [ $osFamily = Darwin ]; then
			: # TO DO
		fi

#		echo $PATH | grep -q $texlivePrefix || export PATH=$texlivePrefix/bin:$PATH
	fi
}

TeXLiveInstall "$@"
