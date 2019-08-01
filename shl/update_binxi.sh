#!/usr/bin/env sh

update_binxi() {
	local scriptDir=$(dirname $0)
	scriptDir=$(cd $scriptDir;pwd)
	
	mkdir -pv $scriptDir/not_mine/
	rm -v $scriptDir/not_mine/binxi
	LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P ~/.local/share/man/man1/ https://raw.githubusercontent.com/smxi/inxi/inxi-legacy/binxi.1
	#LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P $scriptDir/not_mine/ https://raw.githubusercontent.com/smxi/inxi/inxi-legacy/binxi
	LANG=C \curl -q --no-progress-bar -C - -R -z $scriptDir/not_mine/binxi -o $scriptDir/not_mine/binxi https://raw.githubusercontent.com/smxi/inxi/inxi-legacy/binxi
	chmod +x $scriptDir/not_mine/binxi
}

update_binxi
