#!/usr/bin/env bash

#Creation du .cache dans /tmp et pointage de ce dernier via un lien symbolique
if [ $(uname -s) = Linux ] || [ $(uname -s) = Darwin ]
then
	myCacheRootDir=/tmp/$LOGNAME
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
