#!/usr/bin/env bash

os=$(uname -s)
if [ $os = Linux ]
then
	[ $# = 0 ] && {
		echo  "=> Usage: $0 programName"
		exit 1
	}
	
	programName="$1"
	appName="$(echo $programName | sed 's/^./\U&/')"
	destopFilePath=~/.local/share/applications/$1.desktop
	FORM=$(zenity --forms --title="Simple shortcut maker" --text="Create new .desktop file" \
		--add-entry="Program Name" \
		--add-entry="Command or path to file" \
		--add-combo="Terminal app (true/false)" --combo-values "false|true" \
		--add-entry="Icon (path)")
	
	[ $? = 0 ] || exit 2
	
	awk -F'|' '{
		print "#!/usr/bin/env xdg-open"
		print "[Desktop Entry]"
		print "Type=Application"
		print "Name="$1
		print "Exec="$2
		print "Terminal="$3
		if ($4 !~ /^[ ]*$/) print "Icon="$4
	}' <<< "$FORM" > $destopFilePath && chmod -v +x $destopFilePath && ls -l $destopFilePath
fi
