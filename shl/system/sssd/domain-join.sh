#!/usr/bin/env bash

if ! which adcli &>/dev/null;then
	echo "==> Installing adcli realmd ..."
	sudo apt-get install adcli realmd -y >/dev/null
fi

NAME=$(source /etc/os-release;echo $NAME)
VERSION_ID=$(source /etc/os-release;echo $VERSION_ID)

OU="OU=MY-OU-DistinguishedName"
domain=MY-DOMAIN
user=MY-USER

logDIR=../log
mkdir -p $logDIR
echo "=> Jonction au domain $domain ..." | tee $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log
sudo adcli testjoin || sudo realm join -v --user=$user --computer-ou="$OU" --os-name=$NAME --os-version=$VERSION_ID $domain 2>&1 | tee -a $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log

sudo pam-auth-update --enable mkhomedir 2>&1 | tee -a $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log # Au cas ou le homedir n'est pas cree
