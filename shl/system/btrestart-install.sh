#!/usr/bin/env bash

initPath=$(ps -p 1 -o cmd= | cut -d" " -f1)
set -o pipefail
systemType=$(strings $initPath | egrep -o "upstart|sysvinit|systemd" | head -1 || echo unknown)
set +o pipefail

btrestartServiceScript=/usr/local/bin/btrestart.sh
btrestartServiceName=btrestart
	if ! [ -s $btrestartServiceScript ];then
		printf '#!/bin/sh\n\n'
		echo 'service bluetooth stop;sleep 1;service bluetooth start;sleep 1;service bluetooth status'
	fi | sudo tee $btrestartServiceScript

	[ -x $btrestartServiceScript ] || sudo chmod -v +x $btrestartServiceScript

if [ $systemType = systemd ];then
	if ! [ -s /lib/systemd/system/$btrestartServiceName.service ];then
		cat<<-EOF | sudo tee /lib/systemd/system/$btrestartServiceName.service
			[Unit]
			Description=Restart Bluetooth after resume
			After=suspend.target

			[Service]
			Type=simple
			ExecStart=$btrestartServiceScript

			[Install]
			WantedBy=suspend.target
EOF
		sudo systemctl daemon-reload
	fi

	systemctl is-enabled --quiet $btrestartServiceName.service || sudo systemctl enable $btrestartServiceName.service
	systemctl is-active  --quiet $btrestartServiceName.service || { echo "=> INFO: Need to start $btrestartServiceName.service.">&2;sudo systemctl start $btrestartServiceName.service; sleep 3; }
fi

sudo service bluetooth status
