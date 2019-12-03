#!/usr/bin/env bash

osFamily=$(uname -s)
if [ $osFamily = Linux ]
then
	[ $# = 0 ] && {
		echo  "=> Usage: $0 desktopShortcutFileName"
		exit 1
	}
	
	desktopShortcutFileName="$1"
	appName="$(echo $desktopShortcutFileName | sed 's/^./\U&/')"
	destopFilePath=~/.local/share/applications/$desktopShortcutFileName.desktop
	FORM=$(zenity --forms --title="Simple application shortcut maker" --text="Create new application .desktop file" \
			--add-entry="Program Name" \
			--add-entry="Command or path to file" \
			--add-combo="Terminal app (true/false)" --combo-values "false|true" \
			--add-entry="Icon (path)" \
		  )
	
	[ $? = 0 ] || exit 2
	
	echo
	awk -F'|' '{
		print "#!/usr/bin/env xdg-open"
		print "[Desktop Entry]"
		print "Type=Application"
		print "Name="$1
		print "Exec="$2
		print "Terminal="$3
		if ($4 !~ /^[ ]*$/) print "Icon="$4
	}' <<< "$FORM" | tee $destopFilePath && echo && chmod -v +x $destopFilePath && echo && ls -l $destopFilePath
fi
