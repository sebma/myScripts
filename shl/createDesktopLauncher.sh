#!/usr/bin/env bash

[ $# = 0 ] && {
	echo  "=> Usage: $0 programName"
	exit 1
}

FORM=$(zenity --forms \ --title="Simple shortcut maker" --text="Create new .desktop file" \
        --add-entry="Program Name" \
        --add-entry="Command or path to file" \
        --add-entry="Terminal app (true/false)" \
        --add-entry="Icon (path)")

[ $? = 0 ] || exit 2

awk -F'|' -v home="$HOME" -v programName="$1" 'BEGIN {
    FILE = home"/.local/share/applications/"programName".desktop"
}{
        print "[Desktop Entry]" >> FILE
        print "Type=Application" >> FILE
        print "Name="$1 >> FILE
        print "Exec="$2 >> FILE
        print "Terminal="$3 >> FILE
        if ($4 !~ /^[ ]*$/)
            print "Icon="$4 >> FILE ;
    system("chmod 755 " FILE);
}' <<< "$FORM" && ls -l ~/.local/share/applications/$1.desktop
