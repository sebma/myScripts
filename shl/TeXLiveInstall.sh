#!/usr/bin/env sh

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)

TeXLiveInstall () {
	osFamily=undefined
	wget=wget
	$(which bash) -c 'echo $OSTYPE' | grep -q android && osFamily=Android || osFamily=$(uname -s)
	if ! which tlmgr > /dev/null 2>&1; then
		if [ $osFamily = Linux ]; then
			$wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
			texLiveDIR=$(tar tf install-tl-unx.tar.gz | awk -F/ '/\/$/{print$(NF-1);exit}')
			texLiveFullVersion=$(tar tf install-tl-unx.tar.gz | awk -F"[/-]" '/\/$/{print$(NF-1);exit}')
			texLiveVersion=$(echo $texLiveVersion | cut -c -4)
			tar xzf install-tl-unx.tar.gz
			if cd $texLiveDIR;then
				if groups | \egrep -wq "adm|admin|sudo|root|wheel"; then
					sudo ./install-tl -scheme scheme-small
					texlivePrefix=/usr/local/texlive/$texLiveVersion
				else
					./install-tl -scheme scheme-small
					texlivePrefix=$HOME/.texlive$texLiveVersion
				fi
				cd - >/dev/null
			fi
#			rm -fr install-tl-unx.tar.gz ./$texLiveDIR/
		elif [ $osFamily = Darwin ]; then
			:
		fi

#		echo $PATH | grep -q $texlivePrefix || export PATH=$texlivePrefix/bin:$PATH
	fi
#	groups | \egrep -wq "adm|admin|sudo|root|wheel" && tlmgr=tlmgr || tlmgr="$(which tlmgr) --usermode"

#	$scriptDir/TeXLivePostInstall.sh
}

TeXLiveInstall "$@"
