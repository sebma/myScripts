#!/usr/bin/env bash
echo "=> Starting <$(basename $0)>..."
syncCommand="rsync -uth -P -m -rl --size-only"
dirList="$(echo ~/{Documents,Downloads,Pictures})"
androidDirList="$(echo ~/android_storage/{DCIM,mysword,.youversion})"
destination=$(df | awk '/ .media.sdcard/{print$NF}')
if [ "$destination" ]
then
	mount | grep -q /android_storage && time $syncCommand --remove-source-files ~/android_storage/.aptoide/apks $destination/.aptoide/
	mount | grep -q /android_storage && test -d ~/android_storage/Android/data/org.fdroid.fdroid/cache/apks/f-droid.org--1/ && time $syncCommand --remove-source-files ~/android_storage/Android/data/org.fdroid.fdroid/cache/apks/f-droid.org--1/ $destination/Android/data/org.fdroid.fdroid/cache/apks/f-droid.org--1/
	mount | grep -q /android_storage && time $syncCommand --exclude ".thumbdata*" $androidDirList $destination/
	set -x
	time $syncCommand --remove-source-files ~/Downloads/apk $destination/Downloads/
	time $syncCommand --exclude ".thumbdata*" --exclude "Pictures/Jolla/*" --exclude "*/mail_attachments/*" $dirList $destination/
	time $syncCommand --remove-source-files ~/Videos $destination/
	time $syncCommand --remove-source-files ~/Recordings $destination/
	sync
else
	echo "=> ERROR: The SD card is not mounted yet, please wait and relaunch <$(basename $0)>." >&2
	exit 1
fi
set +x
echo "=> DONE."
