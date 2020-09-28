#!/usr/bin/env sh

update_inxi() {
	local scriptDir=$(dirname $0)
	local scriptDir=$(cd $scriptDir;pwd)
	local manPATH=~/.local/share/man/man1/
	local binPATH=$scriptDir/../pl/not_mine/

	mkdir -pv $scriptDir/../pl/not_mine/
	rm -v $scriptDir/../pl/not_mine/inxi
	LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P ~/.local/share/man/man1/ https://raw.githubusercontent.com/smxi/inxi/master/inxi.1
	$gzip -9v $manPATH/inxi.1
	#LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P $scriptDir/../pl/not_mine/ https://raw.githubusercontent.com/smxi/inxi/master/inxi
	LANG=C \curl -q --no-progress-bar -C - -R -z $scriptDir/../pl/not_mine/inxi -o $scriptDir/../pl/not_mine/inxi https://raw.githubusercontent.com/smxi/inxi/master/inxi
	chmod +x $scriptDir/../pl/not_mine/inxi
}

update_inxi
