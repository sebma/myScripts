#!/usr/bin/env bash

#Creation du .cache dans /tmp/$USER et pointage de ce dernier via le lien symbolique ~/.cache
function moveCacheTo_tmp {
	local osFamily=$(uname -s)
	local cacheLinkName=.cache
	local myCacheRootDir=/tmp/$USER
	cd $HOME
	if [ $osFamily = Linux ] || [ $osFamily = Darwin ]
	then
		if [ ! -L ~/.cache ]
		then
			mkdir -pv $myCacheRootDir/
			test -d ~/.cache && mv ~/.cache $myCacheRootDir/ || mkdir -pv $myCacheRootDir/.cache/
			cd $HOME && ln -sf $myCacheRootDir/.cache
		else
			#Si le lien symbolique existe mais qu'il ne pointe sur rien alors on cree la cible du lien symbolique
			test -d $myCacheRootDir/.cache/ || mkdir -pv $myCacheRootDir/.cache/
		fi
		echo
	fi
}

moveCacheTo_tmp
