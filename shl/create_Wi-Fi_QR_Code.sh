#!/usr/bin/env bash

ssid=$(zenity --entry --text="Hidden Network name (SSID)" --title="Create WiFi QR")

zenity --question --title="" --text "Is your Wi-Fi network hidden ?" --ok-label=No --cancel-label=Yes && hidden=false || hidden=true

qrencode -s 7 -o $ssid.png "WIFI:S:$ssid;T:WPA;P:$(zenity --password --title="Wifi Password");H:$hidden;;"

nohup eog $ssid.png &
