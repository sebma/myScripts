#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && alias sudo="\sudo " || alias sudo=""

if cd /iso/gentooBased
#if false
then
	systemrescuecd=systemrescuecd-x86-latest.iso.tmp
	mkdir -p /mnt/iso ~/tmp
	test -f $systemrescuecd.aria2 && rm -v $systemrescuecd.aria2
	#if aria2c -c -o $systemrescuecd http://sourceforge.net/projects/systemrescuecd/files/latest/download
	if [ -s $systemrescuecd ]
	then
		if sudo mount $systemrescuecd /mnt/iso
		then
			version=$(cat /mnt/iso/version)
			rsync -aP /mnt/iso ~/tmp
			sync
			chmod u+w ~/tmp/iso
#			fusermount -u /mnt/iso && mv -v systemrescuecd-x86-latest.iso.tmp systemrescuecd-x86-$version.iso
#			ln -vsf systemrescuecd-x86-$version.iso systemrescuecd-x86-latest.iso
		fi
	fi
fi

if false
#if cd ~/tmp/iso
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
fi

if ! df -h | grep media
then
  echo "=> Erreur: Veuillez d abord monter la cle USB"
  exit 1
fi

printf "=> Quel est le device de la cle ? : "
read pendriveDevice
if ! test $pendriveDevice
then
    echo "=> The device name cannot be empty." >&2
    exit 1
fi

echo $pendriveDevice | grep -q /dev/ 2>/dev/null || pendriveDevice=/dev/$pendriveDevice
#pendriveDevice=`echo $pendriveDevice | sed "s/[0-9]$//"`
echo "=> pendriveDevice = $pendriveDevice"

#pendriveMountPoint=`mount | grep $pendriveDevice | sed "s/ type .*//" | awk '{print $3}'`
pendriveMountPoint=`df | grep $pendriveDevice | cut -d/ -f4-`
if ! test "$pendriveMountPoint"
then
  echo "=> Erreur: Veuillez d abord monter $pendriveDevice"
  exit 1
fi

pendriveMountPoint="/$pendriveMountPoint"
echo "=> pendriveMountPoint = $pendriveMountPoint"

partitionDevice=`mount | grep $pendriveDevice | awk '{print $1}'`
echo "=> partitionDevice = $partitionDevice"

function runScriptOnFAT {
	scriptName=$1
	shift
	if [ "$scriptName" ]
	then
		interpreter=$(head -1 "$scriptName" | awk -F '/| ' '{print $NF}')
		$(which $interpreter) "$scriptName" $@
	fi
}

function sudoRunScriptOnFAT {
	scriptName=$1
	shift
	if [ "$scriptName" ]
	then
		interpreter=$(head -1 "$scriptName" | awk -F '/| ' '{print $NF}')
		sudo $(which $interpreter) "$scriptName" $@
	fi
}
	mkdir -p $pendriveMountPoint/EFI/syslinux/
	for file in /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /usr/lib/syslinux/modules/efi64/{ldlinux.e64,menu.c32,libcom32.c32,libutil.c32}; do
		cp -puv $file $pendriveMountPoint/EFI/syslinux/
	done
	sync

#	sudo efibootmgr -c -d $pendriveDevice -p 1 -l /EFI/syslinux/syslinux.efi -L "Syslinux"

	set -ex
	umount $partitionDevice

#	mkdir -p /mnt/usbstick
#	cd /mnt/iso
	cd ~/tmp/iso
	time sudoRunScriptOnFAT usb_inst.sh copyfiles $partitionDevice
#	time sudoRunScriptOnFAT usb_inst.sh syslinux $partitionDevice
#	sudo install-mbr $pendriveDevice
	sync
	sudo umount /mnt/iso
