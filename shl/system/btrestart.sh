#!/bin/sh

[ $(id -u) != 0 ] && sudo=sudo || sudo=""
pulseaudio --kill;sleep 1;pidof pulseaudio >/dev/null || pulseaudio --start --log-target=syslog # Restart pulseaudio
$sudo service bluetooth stop;sleep 1;$sudo service bluetooth start;sleep 1;service bluetooth status
