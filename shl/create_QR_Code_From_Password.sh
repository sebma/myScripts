#!/usr/bin/env bash

os=$(uname -s)
[ $os = Linux ]  && open=xdg-open
[ $os = Darwin ] && open=open
if [ $os = Linux ] || [ $os = Darwin ]
then
	for tool in zenity qrencode
	do
		if ! type -P $tool >/dev/null 2>&1
		then
			echo "=> $0 ERROR: $tool is not installed." >&2
			exit 1
		fi
	done
	qrencode -l H -s 7 -o $USER.WP.png "$(zenity --password --title="Wifi Password")" && nohup $open $USER.WP.png &
else
	echo "=> $0 ERROR: $os is not supported yet." >&2
	exit 2
fi
