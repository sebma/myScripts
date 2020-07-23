#!/usr/bin/env sh

varMailPartition=/var/mail

if ! df $varMailPartition | grep $varMailPartition;then
	echo "=> You must have a separate $varMailPartition partition." >&2
	exit 1
fi

rsync=$(which rsync)
move="$rsync -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION -ogpuv -lH --remove-source-files"
sudo mkdir -p $varMailPartition/thunderbird/$USER
sudo chown $USER:$USER $varMailPartition/thunderbird/$USER
$move $HOME/.thunderbird/* $varMailPartition/thunderbird/$USER || exit $?
ln -svf $varMailPartition/thunderbird/$USER $HOME/.thunderbird
sync
