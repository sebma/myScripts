#!/usr/bin/env sh

set -o nounset
set -o errexit
jollaUSBNetwork=192.168.2.14/31
jollaUSBIP=$(ipcalc $jollaUSBNetwork | awk '/HostMax:/{print$2}')
jollaUSBInterface=usb0
ifconfig $jollaUSBInterface >/dev/null || exit
[ $(id -ru) != 0 ] && sudo ifconfig $jollaUSBInterface inet $jollaUSBNetwork || ifconfig $jollaUSBInterface inet $jollaUSBNetwork
nc -v -z -w 5 $jollaUSBIP ssh && ssh nemo@$jollaUSBIP
