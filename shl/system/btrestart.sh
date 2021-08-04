#!/bin/sh

[ $(id -u) != 0 ] && sudo=sudo || sudo=""
echo "=> Restarting the pulseaudio server ..."
pulseaudio --kill;sleep 1;pidof pulseaudio >/dev/null || pulseaudio --start --log-target=syslog # Restart pulseaudio
sleep 1
ps -fC pulseaudio
echo "=> Restarting the bluetooth service ..."
$sudo service bluetooth stop;sleep 1;$sudo service bluetooth start;sleep 1;service bluetooth status
# echo && \journalctl -u bluetooth -n 20
