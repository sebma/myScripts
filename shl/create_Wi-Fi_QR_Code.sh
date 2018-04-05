#!/usr/bin/env bash

ssid=$(zenity --entry --text="Hidden Network name (SSID)" --title="Create WiFi QR")
qrencode -s 7 -o $ssid.png "WIFI:S:$ssid;T:WPA;P:$(zenity --password --title="Wifi Password");H:true;;"
nohup eog $ssid.png &
