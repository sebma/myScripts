#!/usr/bin/env bash
# This script installs systemd and its dependencies on a Linux system.

set -o nounset
scriptBaseName=${0/*\//}
if [ $# != 1 ];then
        echo "=> Usage $scriptBaseName SERVICE_NAME" >&2
        exit 1
fi
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

SERVICE_NAME=$1

# Check if the /etc/systemd/system/$SERVICE_NAME exists
if [ ! -f /etc/systemd/system/$SERVICE_NAME ]; then
    $sudo cp -piv $SERVICE_NAME /etc/systemd/system/$SERVICE_NAME
fi

$sudo systemctl daemon-reload
$sudo systemctl enable $SERVICE_NAME
$sudo systemctl start $SERVICE_NAME
$sudo systemctl status $SERVICE_NAME
