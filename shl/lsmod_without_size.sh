#!/bin/sh
lsmod | awk '{printf "%-20s\t%s\n",$1,$4}' | tail -n +2
