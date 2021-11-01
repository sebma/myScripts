#!/usr/bin/env sh

ventoyROOT=/opt/ventoy
Ventoy2DiskScript=$ventoyROOT/Ventoy2Disk.sh
ls -l $Ventoy2DiskScript | grep -q "root $USER" || sudo chgrp $USER $Ventoy2DiskScript
test ! -x $Ventoy2DiskScript && sudo chmod g+x $Ventoy2DiskScript

if cd $ventoyROOT;then
	if [ $(id -u) != 0 ];then
		if set -o | \grep -q xtrace.*on;then
			sudo bash -x ./$(basename $Ventoy2DiskScript) "$@"
		else
			sudo ./$(basename $Ventoy2DiskScript) "$@"
		fi
	else
		./$(basename $Ventoy2DiskScript) "$@"
	fi
fi
