#!/usr/bin/env sh

[ -d /sys/firmware/efi ] && echo "Session EFI" || echo "Session non-EFI"
efibootmgr
