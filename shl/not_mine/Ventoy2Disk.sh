#!/usr/bin/env sh

Ventoy2DiskScript=/opt/ventoy/Ventoy2Disk.sh
ls -l $Ventoy2DiskScript | grep -q "root $USER" || sudo chgrp $USER $Ventoy2DiskScript
test ! -x $Ventoy2DiskScript && sudo chmod g+x $Ventoy2DiskScript

if cd /opt/ventoy;then
	if [ $(id -u) != 0 ];then
		if set -o | \grep -q xtrace.*on;then
			sudo bash -x ./$(basename $Ventoy2DiskScript) "$@"
		else
			sudo ./$(basename $Ventoy2DiskScript) "$@"
		fi
	fi
fi
