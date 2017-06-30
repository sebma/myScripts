#!/bin/sh
(lspci && lshw -businfo -class bridge) | egrep "Host Bridge|PCI-"
echo
lshw -class bridge | egrep -A4 "Host Bridge|PCI-" | grep -v physical

