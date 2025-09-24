#!/usr/bin/env bash
scriptBaseName=${0##*/}

if [ $# != 1 ];then
	echo "=> Usage: $scriptBaseName countryKeyCode"
	exit 1
fi

countryKeyCode=$1
test $(id -u) == 0 && sudo="" || sudo=sudo
$sudo mkdir -v /boot/grub/layouts
$sudo grub-kbdcomp -o /boot/grub/layouts/$countryKeyCode.gkb $countryKeyCode

grep "insmod keylayouts" -q /etc/grub.d/40_custom || echo "insmod keylayouts" | $sudo tee -a /etc/grub.d/40_custom >/dev/null
grep $countryKeyCode -q /etc/grub.d/40_custom || echo keymap $countryKeyCode | $sudo tee -a /etc/grub.d/40_custom >/dev/null
$sudo update-grub
