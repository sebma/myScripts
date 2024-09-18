#!/usr/bin/env bash

logDIR=../log
mkdir -p $logDIR
{
echo "=> DMI Product name : "
cat /sys/class/dmi/id/product_name
echo "=> systemd-cryptenroll --tpm2-device=list ..."
systemd-cryptenroll --tpm2-device=list
sudo sysctl -w kernel.dmesg_restrict=0 -q
echo "=> dmesg | grep -i tpm ..."
dmesg | grep -i tpm
if ! which tpm2 &>/dev/null;then
	echo "==> Installing tpm2-tools ..."
	sudo apt-get install tpm2-tools -y >/dev/null
fi
echo "=> sudo tpm2 getcap properties-variable ..."
sudo tpm2 getcap properties-variable
} | tee $logDIR/tpm_infos-$HOSTNAME-$(date +%Y%m%d).log
