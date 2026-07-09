#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

swapFilePath=$1
if [ ! -e $swapFilePath ];then
	$sudo fallocate -l $swapSize $swapFilePath
	$sudo chmod 0600 $swapFilePath
	$sudo mkswap $swapFilePath
	$sudo swapon $swapFilePath
	grep $swapFilePath /etc/fstab -q || echo "$swapFilePath none swap sw 0 0" | $sudo tee -a /etc/fstab
	$sudo systemctl daemon-reload
fi
