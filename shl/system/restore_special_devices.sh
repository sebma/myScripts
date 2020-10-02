#!/usr/bin/env bash

declare -A fsTypesNDevices
fsTypesNDevices[/dev]="devtmpfs dev"
fsTypesNDevices[/dev/pts]="devpts devpts"
fsTypesNDevices[/proc]="proc proc"
fsTypesNDevices[/run]="tmpfs run"
fsTypesNDevices[/sys]="sysfs sys"
fsTypesNDevices[/sys/firmware/efi/efivars]="efivarfs efivarfs"

for special in "${!fsTypesNDevices[@]}"
do
	df -T $special | grep -q $special || sudo mount -v -t ${fsTypesNDevices[$special]} $special
done
