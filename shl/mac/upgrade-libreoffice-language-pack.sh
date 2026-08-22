#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

if [ $(uname -s) == Darwin ];then
	# brew reinstall --cask libreoffice-language-pack --language=fr
	brew fetch --cask libreoffice-language-pack
	open -W -a libreoffice
	#open -W $(brew --cache --cask libreoffice-language-pack)
	dmgMountDir=$(hdiutil attach $(brew --cache --cask libreoffice-language-pack) | awk '/Volumes.LibreOffice/{for(i=3;i<NF;++i)printf$i" ";print$NF}')
	ls "$dmgMountDir/LibreOffice Language Pack.app" && $sudo "$dmgMountDir/LibreOffice Language Pack.app/Contents/LibreOffice Language Pack" || exit
	vdisk=$(df | awk '/LibreOffice/{print$1}')
	diskutil eject $vdisk
fi
