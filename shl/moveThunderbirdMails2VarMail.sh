#!/usr/bin/env bash

LANGUAGE=C
varMailPartition=/var/mail

if ! df $varMailPartition | grep -q $varMailPartition;then
	echo "=> You must have a separate $varMailPartition partition." >&2
	exit 1
fi

rsync=$(which rsync)
move="$rsync -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION -ogpuv -lH --remove-source-files"

test -d $varMailPartition/thunderbird/$USER || { groups | grep -q sudo && sudo mkdir -v -p $varMailPartition/thunderbird/$USER || exit; }
ls -ld $varMailPartition/thunderbird/$USER | grep -q "$USER " || { groups | grep -q sudo && sudo chown -v $USER:$USER $varMailPartition/thunderbird/$USER || exit; }

if [ -e $HOME/.thunderbird ];then
	if ! [ -L $HOME/.thunderbird ];then
		set -x
		$move -r $HOME/.thunderbird/* $varMailPartition/thunderbird/$USER || exit
		find $HOME/.thunderbird/ -type d -empty -delete
		ln -svf $varMailPartition/thunderbird/$USER $HOME/.thunderbird
		sync
	fi
fi
