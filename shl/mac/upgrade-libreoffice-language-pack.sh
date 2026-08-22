#!/usr/bin/env bash

if [ $(uname -s) == Darwin ];then
	# brew reinstall --cask libreoffice-language-pack
	brew fetch --cask libreoffice-language-pack
	open -W -a libreoffice
	open -W $(brew --cache --cask libreoffice-language-pack)
	read
	vdisk=$(df | awk '/LibreOffice/{print$1}')
	diskutil eject $vdisk
fi
