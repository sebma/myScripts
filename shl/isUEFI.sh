#!/usr/bin/env bash

type -P efibootmgr >/dev/null 2>&1 && efibootmgr -q && echo "Session EFI" || echo "Session non-EFI"
type -P efivar >/dev/null 2>&1 && efivar -l >/dev/null && echo "Session EFI" || echo "Session non-EFI"
[ -d /sys/firmware/efi ] && echo "Session EFI" || echo "Session non-EFI"
