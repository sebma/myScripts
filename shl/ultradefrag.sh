#!/usr/bin/env bash

ultraDefrag=ultradefrag-5.0.0AB.7.zip
if ! type -P udefrag &>/dev/null
then
	wget -nv http://jp-andre.pagesperso-orange.fr/$ultraDefrag
	if unzip -n $ultraDefrag
	then
		cd ${ultraDefrag/.zip/}
		aria2c https://dl.dropboxusercontent.com/u/14775223/Various/${ultraDefrag/.zip/.patch}
		sync
		pwd
		set -x
		patch --verbose -p1 ${ultraDefrag/.zip/.patch}
		cd ./src && make
	fi
fi
