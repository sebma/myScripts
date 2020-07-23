#!/usr/bin/env sh

varMailPartition=/var/mail

if ! df $varMailPartition | grep -q $varMailPartition;then
	echo "=> You must have a separate $varMailPartition partition." >&2
	exit 1
fi

rsync=$(which rsync)
move="$rsync -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION -ogpuv -lH --remove-source-files"

test -d $varMailPartition/thunderbird/$USER || sudo mkdir -v -p $varMailPartition/thunderbird/$USER
ls -ld $varMailPartition/thunderbird/$USER | grep -q $USER || sudo chown -v $USER:$USER $varMailPartition/thunderbird/$USER

if [ -e $HOME/.thunderbird ];then
	if ! [ -L $HOME/.thunderbird ];then
		$move $HOME/.thunderbird/* $varMailPartition/thunderbird/$USER || exit
		rmdir -v $HOME/.thunderbird/
		ln -svf $varMailPartition/thunderbird/$USER $HOME/.thunderbird
		sync
	fi
fi
