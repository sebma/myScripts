#!/usr/bin/env bash

setleds +num
which sudo >/dev/null 2>&1 && sudo="sudo" || sudo=""
pgrep gpm >/dev/null || gpm -m /dev/input/mouse0 -t ps2
#time $sudo emerge-webrsync -v || time $sudo emerge --sync && $sudo etc-update --automode -3
eselect news read >/dev/null
#usbPendriveMountPoint=$(df | awk "/.dev.sdd1/"'{print$NF}')
usbPendriveMountPoint=/livemnt/boot
#cd $usbPendriveMountPoint/clonezillaSrc/drbl-*/ && make DESTDIR=$usbPendriveMountPoint/clonezilla install
#cd $usbPendriveMountPoint/clonezillaSrc/drbl-*/ && make install
#cd $usbPendriveMountPoint/clonezillaSrc/clonezilla-*/ && make install
cd $usbPendriveMountPoint/clonezillaSrc/ && {
	mkdir -p ~/src
	tar -C ~/src -xjf drbl-*.tar.bz2*
	tar -C ~/src -xjf clonezilla-*.tar.bz2*
	cd ~/src/drbl-*/ && make && $sudo make install || exit
	cd ~/src/clonezilla-*/ && $sudo make install
	chmod +x /usr/sbin/clonezilla
	which clonezilla && {
		rm -fr ~/src/drbl-*/ ~/src/clonezilla-*/
		sync
	}
}
