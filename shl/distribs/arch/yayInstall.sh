#!/usr/bin/env bash

function yayInstall () {
	if ! yay -V > /dev/null 2>&1; then
		sudo pacman -S --needed git base-devel --noconfirm
		if ! sudo pacman -S --needed yay --noconfirm; then
			mkdir -pv ~/git/aur
			git clone https://aur.archlinux.org/yay-bin.git
			cd yay-bin
			sudo makepkg -si
		fi
	fi
}

yayInstall
