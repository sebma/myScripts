#!/usr/bin/env bash

sudo -b kvm -m 1G -bios /usr/share/qemu/OVMF.fd -hda /dev/sdb
