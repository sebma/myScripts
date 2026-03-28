#!/usr/bin/env bash
# This script installs systemd and its dependencies on a Linux system.

set -o nounset
scriptBaseName=${0/*\//}
if [ $# != 1 ];then
        echo "=> Usage $scriptBaseName serviceFileName" >&2
        exit 1
fi
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

serviceFileName=$1

# Check if the /etc/systemd/system/$serviceFileName exists
if [ ! -f /etc/systemd/system/$serviceFileName ]; then
    $sudo cp -piv $serviceFileName /etc/systemd/system/$SERVICE_NAME
fi

$sudo systemctl daemon-reload
$sudo systemctl enable $serviceFileName
$sudo systemctl start $serviceFileName
$sudo systemctl status $serviceFileName
