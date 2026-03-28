#!/usr/bin/env bash

set -o nounset
scriptBaseName=${0/*\//}
if [ $# != 2 ];then
	echo "=> Usage $scriptBaseName serviceName workingDirectory" >&2
	exit 1
fi
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

serviceName=$1
workingDirectory=$2
cat <<-EOF | tee $serviceName.service
[Unit]
Description=$serviceName Service
Requires=docker.service
After=docker.service

[Service]
Type=simple
WorkingDirectory=$workingDirectory # Need to point the folder where your docker-compose is located
Environment=ENVIRONMENT=production # Put any environments you want to pass into docker
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=always
RestartSec=10s
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

ls -l $serviceName.service
