#!/bin/sh
[ "`id -u`" = "0" ] || { echo "You need root privileges to modify the system!" >&2 ; exit 1; }
[ -d "$1" ] && CONFIGS="$1/configs.tbz"
[ -f "$CONFIGS" ] || CONFIGS="/cdrom/KNOPPIX/configs.tbz"
[ -f "$CONFIGS" ] || CONFIGS="/media/fd0/configs.tbz"
if [ -f "$CONFIGS" ]; then
echo "[1mExtracting config archive $CONFIGS...[0m"
tar -jpPtf "$CONFIGS" | while read i; do rm -f "$i"; done
tar -jpPxf "$CONFIGS" ; chown -R knoppix.knoppix /home/knoppix
cd $1 && ./shl/install_packages.sh
cd -
fi
killall pump 2>/dev/null && sleep 2 && killall -9 pump 2>/dev/null && sleep 2
echo "[1mStarting daemons...[0m"
for i in  ifupdown networking cupsys; do [ -x /etc/init.d/$i ] && /etc/init.d/$i start; done
