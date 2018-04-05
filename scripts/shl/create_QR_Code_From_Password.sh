#!/usr/bin/env bash

qrencode -s 7 -o $USER.WP.png "$(zenity --password --title="Wifi Password")"
nohup eog $USER.WP.png &
