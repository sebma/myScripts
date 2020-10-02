#!/usr/bin/env sh

Ventoy2DiskScript=/opt/ventoy/Ventoy2Disk.sh
ls -l $Ventoy2DiskScript | grep -q "root $USER" || sudo chgrp $USER $Ventoy2DiskScript
test ! -x $Ventoy2DiskScript && sudo chmod g+x $Ventoy2DiskScript

cd /opt/ventoy && $(basename $Ventoy2DiskScript) "$@"
