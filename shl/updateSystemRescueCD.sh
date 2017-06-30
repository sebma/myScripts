#!/usr/bin/env bash

if cd /iso/gentooBased
then
	systemrescuecd=systemrescuecd-x86-latest.iso.tmp
	mkdir -p /mnt/iso ~/tmp
	rm -v $systemrescuecd.aria2
	if aria2c -c -o $systemrescuecd http://sourceforge.net/projects/systemrescuecd/files/latest/download
	then
		if fuseiso $systemrescuecd /mnt/iso
		then
			version=$(cat /mnt/iso/version)
			rsync -aP /mnt/iso ~/tmp
			sync
			chmod u+w ~/tmp/iso
			fusermount -u /mnt/iso && mv -v systemrescuecd-x86-latest.iso.tmp systemrescuecd-x86-$version.iso
			ln -vsf systemrescuecd-x86-$version.iso systemrescuecd-x86-latest.iso
		fi
	fi
fi

if cd ~/tmp/iso
then
	cat << EOF > usb_inst.sh.patch
--- usb_inst.sh	2015-02-02 10:11:48.000000000 +0100
+++ usb_inst.sh	2015-09-14 00:50:57.148353608 +0200
@@ -457,19 +457,19 @@
			status="\${status}Installation on \${devname2} in progress\n\n"
			status="\${status}details will be written in \${logfile}\n"
			dialog_status "\${status}"
-			status="\${status}* Writing MBR on \${devname2}\n"
-			dialog_status "\${status}"
-			do_writembr \${devname2} >> \${logfile} 2>&1
-			[ \$? -ne 0 ] && dialog_die "Failed to write the MBR on \${devname2}"
-			sleep 1
-			output="\$(find_first_partition \${devname2})\n"
-			devname2="\${devname2}\$?"
-			dialog_status "\${status}"
-			sleep 5
-			status="\${status}* Creating filesystem on \${devname2}...\n"
-			dialog_status "\${status}"
-			do_format \${devname2} >> \${logfile} 2>&1
-			[ \$? -ne 0 ] && dialog_die "Failed to create the filesystem on \${devname2}"
+#			status="\${status}* Writing MBR on \${devname2}\n"
+#			dialog_status "\${status}"
+#			do_writembr \${devname2} >> \${logfile} 2>&1
+#			[ \$? -ne 0 ] && dialog_die "Failed to write the MBR on \${devname2}"
+#			sleep 1
+#			output="\$(find_first_partition \${devname2})\n"
+#			devname2="\${devname2}\$?"
+#			dialog_status "\${status}"
+#			sleep 5
+#			status="\${status}* Creating filesystem on \${devname2}...\n"
+#			dialog_status "\${status}"
+#			do_format \${devname2} >> \${logfile} 2>&1
+#			[ \$? -ne 0 ] && dialog_die "Failed to create the filesystem on \${devname2}"
			status="\${status}* Copying files (please wait)...\n"
			dialog_status "\${status}"
			do_copyfiles \${devname2} >> \${logfile} 2>&1
EOF
#	patch < usb_inst.sh.patch
#	sudo ./usb_inst.sh
fi
	partName=$(mount | awk  "/media\/$USER/"'{print$1}' || exit)
	umount $partName
	time sudo ./usb_inst.sh copyfiles $partName
	time sudo ./usb_inst.sh syslinux $partName
	sync
