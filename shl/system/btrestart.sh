#!/usr/bin/env bash

initPath=$(ps -p 1 -o cmd= | cut -d" " -f1)
set -o pipefail
systemType=$(strings $initPath | egrep -o "upstart|sysvinit|systemd" | head -1 || echo unknown)
set +o pipefail
[ $(id -u) != 0 ] && sudo=sudo || sudo=""
echo "=> Restarting the pulseaudio server ..."
pulseaudio --kill;sleep 1;pidof pulseaudio >/dev/null || pulseaudio --start --log-target=syslog # Restart pulseaudio
sleep 1
ps -fC pulseaudio
echo "=> Restarting the bluetooth service ..."
$sudo service bluetooth stop;sleep 1;$sudo service bluetooth start;sleep 1
if [ $systemType = systemd ];then
	systemctl status bluetooth -n 0
	echo && \journalctl -u bluetooth -n 15
else
	service bluetooth status
fi
