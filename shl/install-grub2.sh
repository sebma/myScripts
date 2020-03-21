#!/bin/sh

set -o errexit
set -o nounset

echo "Quel est le device de la cle ? : "
df | awk '/media/{print$1" => "$NF}'
read pendriveDevice
echo $pendriveDevice | grep -q /dev/ 2>/dev/null || pendriveDevice=/dev/$pendriveDevice
pendriveDevice=$(echo $pendriveDevice | sed "s/[0-9]$//")
echo "pendriveDevice = $pendriveDevice"

pendriveMountPoint=$(df | grep $pendriveDevice | awk '{print $NF}')
test "$pendriveMountPoint" || {
	echo "=> Erreur: Veuillez d abord monter $pendriveDevice"
	exit 1
}
echo "pendriveMountPoint = $pendriveMountPoint"

partitionDevice=$(mount | grep $pendriveDevice | awk '{print $1}')
echo "partitionDevice = $partitionDevice"

fsType=$(df -T | grep $pendriveDevice | awk '{print $2}')
case $fsType in
	ext4) fsType=ext2 ;;
	vfat) fsType=fat ;;
	fuseblk) fsType=ntfs ;;
	*) ;;
esac

echo "fsType = $fsType"
#echo "module = `ls /usr/lib/grub/i386-pc/$fsType.mod`"

echo $partitionDevice | grep -q "${pendriveDevice}[^1]" && cd /media/boot/.. || cd "$pendriveMountPoint"
grubDir=boot/grub
	echo "=> currDir= `pwd`"
	mkdir -vp $grubDir/
	sudo grub-mkdevicemap -m $grubDir/device.map
#	sudo grub-mkconfig -o $grubDir/grub.cfg
	echo "Utilisation de grub-install version $(grub-install -V | awk '{print$NF}')"
	date +"Il est %T, lancement de grub-install (cela peut durer jusqu'a 4 minutes suivant la version de grub)..."
	sudo time -p grub-install --recheck --root-directory=. $pendriveDevice --modules=$fsType
	locate unicode.pf2 | grep /usr | head -1 | xargs -ri sudo cp -v {} $grubDir/
	sudo cp -v $(locate -r syslinux/memdisk$) $grubDir/
#	See /usr/share/X11/xkb/symbols/*
	grub-kbdcomp -o fr.gkb fr || ckbcomp fr | sudo grub-mklayout -v -o $grubDir/fr.gkb
	grub-kbdcomp -o en.gkb gb || ckbcomp gb | sudo grub-mklayout -v -o $grubDir/en.gkb
	grub-kbdcomp -o us.gkb us || ckbcomp us | sudo grub-mklayout -v -o $grubDir/us.gkb
	test -s /etc/grub.d/40_custom && {
		grep -q at_keyboard /etc/grub.d/40_custom || echo terminal_input at_keyboard
		grep -q keylayouts /etc/grub.d/40_custom || echo insmod keylayouts
		grep -q keymap /etc/grub.d/40_custom || echo keymap fr
	} | sudo tee -a /etc/grub.d/40_custom
	test -s $grubDir/grub.cfg && {
		grep -q at_keyboard $grubDir/grub.cfg || echo terminal_input at_keyboard
		grep -q keylayouts $grubDir/grub.cfg || echo insmod keylayouts
		grep -q keymap $grubDir/grub.cfg || echo keymap fr
	} | sudo tee -a $grubDir/grub.cfg
	sync
	cd
	sudo parted $pendriveDevice set 1 boot on
	sudo umount -v $pendriveMountPoint && test -d $pendriveMountPoint && sudo rmdir -v $pendriveMountPoint
