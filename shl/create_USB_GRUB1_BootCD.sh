#!/usr/bin/env bash

cd $HOME
mkdir -p $HOME/iso/boot/grub

cp /usr/lib/grub/i386-pc/stage2_eltorito $HOME/iso/boot/grub
cp /cdrom/casper/initrd.gz $HOME/iso/boot/
cp /cdrom/casper/vmlinuz $HOME/iso/boot/

cp /etc/initramfs-tools/modules modules
cat >> modules <<-EOF
	### This is a reminder that these modules have been added to allow a CD to boot a USB drive
	usbcore
	sd_mod
	ehci_hcd
	uhci_hcd
	ohci_hcd
	usb-storage
	scsi_mod
EOF
sudo mv modules /etc/initramfs-tools/modules

(
echo "### This makes the bootup wait until any USB drives are ready"
echo WAIT=15
cat /etc/initramfs-tools/initramfs.conf
) > initramfs.conf
sudo mv initramfs.conf /etc/initramfs-tools/initramfs.conf

#sudo mkinitramfs -o $HOME/iso/boot/initrd.gz `uname -r`
sudo mkinitramfs -o $HOME/iso/boot/initrd.gz

cat > $HOME/iso/boot/grub/menu.lst <<-EOF
	title Run Ubuntu 9.04 beta from USB DISK
	root (cd)
	kernel /boot/vmlinuz file=/cdrom/preseed/ubuntu.seed boot=casper noprompt cdrom-detect/try-usb=true persistent
	initrd /boot/initrd.gz
	boot
EOF

sync

sudo mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o $HOME/UbuntuGrubBootCDForUSB.iso $HOME/iso/
sync
