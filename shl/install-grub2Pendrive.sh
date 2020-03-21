#!/usr/bin/env bash

cp="$(which cp) -puv"
type sudo >/dev/null 2>&1 && sudo="$(which sudo)" || sudo=""

df -h | grep media
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

grubFSModulName=`df -T | grep $pendriveDevice | awk '{print $2}'`
case $grubFSModulName in
	ext4) grubFSModulName=ext2 ;;
	vfat) grubFSModulName=fat ;;
	fuseblk) grubFSModulName=ntfs ;;
	*) ;;
esac

echo "=> grubFSModulName = $grubFSModulName"
#echo "=> module = `ls /usr/lib/grub/i386-pc/$grubFSModulName.mod`"

#Si /boot est present dans une partition dediee, va dans /media
#echo $partitionDevice | grep -q "${pendriveDevice}[^1]" && cd /media || cd "$pendriveMountPoint"
test -d "$pendriveMountPoint/grub" && cd /media || cd "$pendriveMountPoint"

	test -f ./etc/default/grub && $sudo $cp ./etc/default/grub /etc/default/grub
	mkdir -p ./boot/grub/ ./boot/efi
	cd ./boot/grub/
	echo "=> currDir= `pwd`"

	grub-mkdevicemap -m device.map
	locate unicode.pf2 | grep /usr/ | head -1 | xargs -ri $cp {} .
	locate -r syslinux/memdisk$ | grep /usr/ | head -1 | xargs -ri $cp {} .
	grub-kbdcomp -o fr.gkb fr || ckbcomp fr | grub-mklayout -o fr.gkb
	grub-kbdcomp -o en.gkb gb || ckbcomp gb | grub-mklayout -o en.gkb
	grub-kbdcomp -o us.gkb gb || ckbcomp gb | grub-mklayout -o us.gkb
	test -f fr.gkb || $sudo $cp fr.gkb /boot/grub/
	grep -q "set -e" `which grub-mkconfig` && $sudo sed -i "/set -e/d" `which grub-mkconfig` # on enleve le "set -e" du script /usr/sbin/grub-mkconfig si present
	test -s /etc/grub.d/40_custom && {
		grep -q at_keyboard /etc/grub.d/40_custom || echo terminal_input at_keyboard | $sudo tee -a /etc/grub.d/40_custom
		grep -q keylayouts /etc/grub.d/40_custom || echo insmod keylayouts | $sudo tee -a /etc/grub.d/40_custom
		grep -q keymap /etc/grub.d/40_custom || echo keymap fr | $sudo tee -a /etc/grub.d/40_custom
	}
	test -s grub.cfg && mv -v grub.cfg grub_`date +%d.%m.%Y_%HH%M`.cfg
	$cp /iso/boot/grub/{*.cfg,*.jpg,*.png} .
	$cp /iso/boot/grub/{*.cfg,*.jpg,*.png} /boot/grub/
set -e
#	test -f grub.cfg && rm -f grub.cfg
#	$sudo grub-mkconfig -o grub.cfg
	for grubScript in $(ls -v /etc/grub.d/* | grep -v 10_linux) ; do
		test -x $grubScript && echo "=> Running $grubScript ..." >&2 && $sudo $grubScript
	done > grub.cfg
	cd -

set +e
	sync
	set -e
	date +"Il est %T, lancement de grub-install pour le mode BIOS (dure environ 1 minutes)..."
	$sudo bash -xc "time grub-install --target i386-pc		--boot-directory $pendriveMountPoint/boot/ --modules \"$grubFSModulName jpeg\" --recheck $pendriveDevice"
	date +"Il est %T, lancement de grub-install pour le mode UEFI 32 (dure environ 1 minutes)..."
	$sudo bash -xc "time grub-install --target i386-efi	 --boot-directory $pendriveMountPoint/boot/ --modules \"$grubFSModulName\" --removable --efi-directory $pendriveMountPoint/boot/ --no-nvram $pendriveDevice"
	date +"Il est %T, lancement de grub-install pour le mode UEFI 64 (dure environ 1 minutes)..."
	$sudo bash -xc "time grub-install --target x86_64-efi --boot-directory $pendriveMountPoint/boot/ --modules \"$grubFSModulName\" --removable --efi-directory $pendriveMountPoint/boot/ --no-nvram $pendriveDevice"
	sync
	$sudo parted $pendriveDevice set 1 boot on

	cd && $sudo umount -vv "$pendriveMountPoint" && test -d "$pendriveMountPoint" && $sudo rmdir "$pendriveMountPoint"
	echo "=> Restauration du boot EFI du PC ..."; $sudo bash -xc "time update-grub"
