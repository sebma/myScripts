#!/usr/bin/env sh

nohup $(which kwin_x11) --replace &
echo "=> Sleeping 10 seconds to wait for KWin to load ..."
sleep 10
pgrep conky && {
	killall conky
	conky -d
	sleep 1
}
echo "=> DONE."
