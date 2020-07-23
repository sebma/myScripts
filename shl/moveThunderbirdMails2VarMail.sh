#!/usr/bin/env sh

varMailPartition=/var/mail

if ! df $varMailPartition | grep $varMailPartition;then
	echo "=> You must have a separate $varMailPartition partition." >&2
	exit 1
fi

sudo mkdir -p $varMailPartition/thunderbird/$USER
sudo chown $USER:$USER $varMailPartition/thunderbird/$USER
mv $HOME/.thunderbird/* $varMailPartition/thunderbird/$USER
ln -svf $varMailPartition/thunderbird/$USER $HOME/.thunderbird
