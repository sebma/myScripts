#!/usr/bin/env sh

for fs in /dev/VG_KINGSTON_SA400S37480G__50026B7282A38811/LV_*;do
	sudo tune2fs -L $(basename $fs | sed "s,LV_,/,;s,_,/,g") $fs
done
