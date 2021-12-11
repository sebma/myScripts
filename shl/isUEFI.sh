#!/usr/bin/env bash

which efibootmgr >/dev/null 2>&1 && efibootmgr -q && echo "Session EFI" || echo "Session non-EFI"
which efivar >/dev/null 2>&1 && efivar -l >/dev/null && echo "Session EFI" || echo "Session non-EFI"
[ -d /sys/firmware/efi ] && echo "Session EFI" || echo "Session non-EFI"
