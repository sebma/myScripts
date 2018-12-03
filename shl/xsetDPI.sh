#!/usr/bin/env sh

xdpyinfo | grep dots
xrandr --dpi 96
xfconf-query -c xsettings -p /Xft/DPI -s 96
xfce4-appearance-settings
