#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(which sudo)

if egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor -q;then
#	Taken from https://askubuntu.com/a/1327781
	cat << EOF | $sudo tee /lib/systemd/system/firstboot.service
[Unit]
Description=One time boot script
[Service]
Type=simple
ExecStart=/firstboot.sh
[Install]
WantedBy=multi-user.target
EOF

	# $sudo systemctl enable firstboot.service # A saisir juste AVANT le clonage de la VM
	$sudo chmod +x /firstboot.sh
fi
