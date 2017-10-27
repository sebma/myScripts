#!/usr/bin/env bash

FORM=$(zenity --forms \ --title="Simple shortcut maker" --text="Create new .desktop file" \
        --add-entry="Program Name" \
        --add-entry="Command or path to file" \
        --add-entry="Terminal app(true/false)" \
        --add-entry="Icon (path)")

[ $? = 0 ] || exit 1

awk -F'|' -v home="$HOME" '{
    FILE = home"/Desktop/"$1".desktop"
        print "[Desktop Entry]" >> FILE
        print "Type=Application" >> FILE
        print "Name="$1 >> FILE
        print "Exec="$2 >> FILE
        print "Terminal="$3 >> FILE
        if ($4 !~ /^[ ]*$/)
            print "Icon="$4 >> FILE ;
    system("chmod 755 " FILE);

}' <<< "$FORM"
