#!/usr/bin/env sh

echo "=> Northbridge Chipset :"
lspci -nnvs 0:0.0 | egrep "^00:|Kernel|Subsystem"
echo "=> Southbridge Chipset :"
lspci | awk '/ISA bridge/{print "lspci -nnvs " $1}' | sh | egrep "^00:|Kernel|Subsystem"
