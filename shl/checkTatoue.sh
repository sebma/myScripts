#!/bin/sh
sudo dd if=/dev/sda count=63 >/tmp/mbr_partiel 2>/dev/null
hexdump -C /tmp/mbr_partiel | egrep -q "OEM|WIN[A-Z0-0]+" && echo Ce PC est tatoue :-\( ! || echo Ce PC ne semble pas tatoue :-\)
rm /tmp/mbr_partiel
