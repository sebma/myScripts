#!/usr/bin/env bash

osFamily=$(uname -s)
if [ $osFamily = Linux ]
then
	[ $# = 0 ] && {
		echo  "=> Usage: $0 URLDesktopFileName"
		exit 1
	}
	
	URLDesktopFileName="$1"_URL
	appName="$(echo $URLDesktopFileName | sed 's/^./\U&/')" # Switch first letter to uppercase
	destopFilePath=~/.local/share/applications/$URLDesktopFileName.desktop
	FORM=$(zenity --forms --title="Simple URL shortcut maker" --text="Create new URL .desktop file" \
			--add-entry="Name of the Web Page" \
			--add-entry="URL of the Web Page" \
		  )
	
	[ $? = 0 ] || exit 2
	
	echo
	awk -F'|' '{
		print "#!/usr/bin/env xdg-open"
		print "[Desktop Entry]"
		print "Type=Link"
		print "Name="$1
		print "URL="$2
		print "Icon=Icon=text-html"
	}' <<< "$FORM" | tee $destopFilePath && echo && chmod -v +x $destopFilePath && echo && ls -l $destopFilePath
fi
