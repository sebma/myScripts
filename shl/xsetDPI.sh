#!/usr/bin/env sh

xdpyinfo | grep dots
xfce4-appearance-settings &
#xrandr --dpi 96
set -x
xfconf-query -c xsettings -p /Xft/DPI
xfconf-query -c xsettings -p /Xft/DPI -s 96
