#!/bin/sh

[ $(id -u) != 0 ] && sudo=sudo || sudo=""
$sudo killall pulseaudio;sleep 1;$sudo service bluetooth start;sleep 1;service bluetooth status
