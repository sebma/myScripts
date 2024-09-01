#!/usr/bin/env bash

initName=$(ps -p 1 -o cmd= | cut -d" " -f1)
initPath=$(type -P $initName)
set -o pipefail
systemType=$(strings $initPath | egrep -o "upstart|sysvinit|systemd|launchd" | head -1 || echo unknown)
set +o pipefail
[ $(id -u) != 0 ] && sudo=sudo || sudo=""

echo "=> Restarting the pulseaudio server ..."
pulseaudio --kill;sleep 1;pidof pulseaudio >/dev/null || pulseaudio --start --log-target=syslog # Restart pulseaudio
# systemctl --user restart pulseaudio.socket
sleep 1s
ps -fC pulseaudio
