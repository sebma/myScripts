#!/usr/bin/env bash

gsettings get org.gnome.desktop.lockdown disable-lock-screen | grep '^false$' -q || gsettings set org.gnome.desktop.lockdown disable-lock-screen false
echo "=> You can now press Super+L to lock your session."
