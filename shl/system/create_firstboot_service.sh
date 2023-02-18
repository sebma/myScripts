#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(which sudo)

# Taken from https://askubuntu.com/a/1327781
cat << EOF | $sudo tee /etc/systemd/system/firstboot.service
[Unit]
Description=One time boot script
[Service]
Type=simple
ExecStart=/firstboot.sh
[Install]
WantedBy=multi-user.target
EOF

cat << EOF | $sudo tee /firstboot.sh
#!/bin/bash 
#SOME COMMANDS YOU WANT TO EXECUTE
systemctl disable firstboot.service 
rm -f /etc/systemd/system/firstboot.service
rm -f /firstboot.sh
EOF

$sudo systemctl enable firstboot.service
$sudo chmod +x /firstboot.sh
