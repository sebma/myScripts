#!/usr/bin/env bash

if [ $(uname -s) == Darwin ];then
	# brew reinstall --cask libreoffice-language-pack
	brew fetch --cask libreoffice-language-pack
	open (brew --cache --cask libreoffice-language-pack)
	open -a libreoffice
fi
