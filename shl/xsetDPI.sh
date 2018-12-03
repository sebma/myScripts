#!/usr/bin/env sh

xdpyinfo | grep dots
xfce4-appearance-settings &
xrandr --dpi 96
xfconf-query -c xsettings -p /Xft/DPI -s 96
