#!/usr/bin/env bash

initName=$(ps -p 1 -o cmd= | cut -d" " -f1)
initPath=$(type -P $initName)
set -o pipefail
systemType=$(strings $initPath | egrep -o "upstart|sysvinit|systemd|launchd" | head -1 || echo unknown)
set +o pipefail
[ $(id -u) != 0 ] && sudo=sudo || sudo=""
pulseaudio=/usr/bin/pulseaudio

echo "=> Restarting the pulseaudio server ..."
ps -fC pulseaudio
pgrep pulseaudio -u $USER >/dev/null && $pulseaudio --kill;sleep 1s
pgrep pulseaudio -u $USER >/dev/null || $pulseaudio --start # Restart pulseaudio
sleep 1s
ps -fC pulseaudio

echo "=> Restarting the bluetooth service ..."
$sudo service bluetooth stop;sleep 1;$sudo service bluetooth start;sleep 1
if [ $systemType = systemd ];then
	systemctl status bluetooth -n 0
	echo && \journalctl -u bluetooth -n 15
else
	service bluetooth status
fi
sleep 1s

echo "=> Starting bluetooth controllers ..."
hciconfig | awk -F'[\t :]+' '/^\w+:/{controller=$1}/\tDOWN/{controller2Start=controller;controller="";print controller2Start}' | while read controller
do
	echo "==> Restarting bluetooth controller <$controller> ..."
	sudo hciconfig $controller down
	sudo hciconfig $controller up
done
sleep 1s
ps -fC pulseaudio
