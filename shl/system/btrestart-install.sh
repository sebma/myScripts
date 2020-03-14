#!/usr/bin/env bash

initPath=$(\ps -p 1 o cmd= | cut -d" " -f1)
systemType=$(strings $initPath | egrep -o "upstart|sysvinit|systemd" | head -1)

if [ $systemType = systemd ];then
	btrestart_service=/usr/local/bin/btrestart.sh
	[ -s $btrestart_service ] || {
		printf '#!/bin/sh\n\n' | sudo tee $btrestart_service
		echo 'systemctl stop bluetooth.service;sleep 1;systemctl --no-block start bluetooth.service' | sudo tee -a $btrestart_service
	}
	[ -x $btrestart_service ] || sudo chmod -v +x $btrestart_service

	[ -s /lib/systemd/system/btrestart.service ] || systemctl -a -t service | grep -q btrestart || {
	sudo cat<<-EOF>/lib/systemd/system/btrestart.service
		[Unit]
		Description=Restart Bluetooth after resume
		After=suspend.target

		[Service]
		Type=simple
		ExecStart=$btrestart_service

		[Install]
		WantedBy=suspend.target
EOF
		sudo systemctl daemon-reload
	}
	systemctl is-enabled --quiet btrestart.service || sudo systemctl enable btrestart.service
	systemctl is-active  --quiet btrestart.service || { echo "=> INFO: Need to start btrestart.service.">&2;sudo systemctl start btrestart.service; sleep 3; }
	service bluetooth status
fi
