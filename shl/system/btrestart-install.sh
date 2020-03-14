#!/usr/bin/env bash

btrestart_service=/usr/local/bin/btrestart.sh
printf '#!/bin/sh\n\n' | sudo tee $btrestart_service
echo 'systemctl --no-block stop bluetooth.service.service;sleep 1;systemctl --no-block start bluetooth.service' | sudo tee -a $btrestart_service
sudo chmod +x $btrestart_service
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
sudo systemctl enable btrestart.service
sudo systemctl daemon-reload
sudo service btrestart start
service btrestart status
