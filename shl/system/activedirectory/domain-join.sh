#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if ! which adcli &>/dev/null;then
	echo "==> Installing realmd adcli ..."
	sudo apt-get install realmd adcli -y >/dev/null
fi

NAME=$(source /etc/os-release;echo $NAME)
VERSION_ID=$(source /etc/os-release;echo $VERSION_ID)

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit
company=companyName

logDIR=../log
mkdir -p $logDIR
echo "=> Test de jonction au domain $domain ..." | tee $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log
if ! time sudo adcli testjoin >/dev/null;then
	echo "=> Jonction au domain $domain ..."
	sudo realm join -v --user=$t2USER --computer-ou="$OU" --os-name=$NAME --os-version=$VERSION_ID $domain 2>&1 | tee -a $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log
	sudo pam-auth-update --enable mkhomedir 2>&1 | tee -a $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log # Au cas ou le homedir n'est pas cree
else
#	sudo grep "_homedir.*/home/%d/%u" /etc/sssd/sssd.conf -q || sudo sed -i-$(date +%Y%m%d-%H%M%S).conf "/_homedir/s|=.*|= /home/%d/%u|" /etc/sssd/sssd.conf
#	if sudo grep "_homedir.*/home/%d" /etc/sssd/sssd.conf -q && ! sudo snap get system homedirs | grep /home/$domain -q;then
#		sudo snap set system homedirs=/home/$domain
#	fi

	sudo grep "_homedir.*/home/%d$" /etc/sssd/sssd.conf -q || sudo sed -i-$(date +%Y%m%d-%H%M%S).conf "/_homedir/s|=.*|= /home/%u|" /etc/sssd/sssd.conf
	sudo sed -i 's/use_fully_qualified_names.*[Tt]rue/use_fully_qualified_names = False/' /etc/sssd/sssd.conf

	if ! sudo grep "simple_allow_groups" /etc/sssd/sssd.conf -q;then
#		echo "simple_allow_groups = T2-Utilisateurs-Ubuntu_Desktop" | sudo tee -a /etc/sssd/sssd.conf
		:
	fi

	if ! sudo grep -i "$adminGroup.*ALL=" /etc/sudoers /etc/sudoers.d/* -q;then
#		echo "%$adminGroup@$domain ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/$company
		echo "%$adminGroup ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/$company
		sudo chmod 440 /etc/sudoers.d/$company
	fi

	groups | grep adm -wq || sudo adduser $USER adm
	if ! grep -i adm:.*$adminGroup /etc/group -q;then
#		sudo sed -i "/adm:/s/$/,$adminGroup@$domain/" /etc/group
		sudo sed -i "/adm:/s/$/,$adminGroup/" /etc/group
		grep adm: /etc/group
	fi

	groups | grep systemd-journal -wq || sudo adduser $USER systemd-journal
	if ! grep -i systemd-journal:.*$adminGroup /etc/group -q;then
#		sudo sed -i "/systemd-journal:/s/$/,$adminGroup@$domain/" /etc/group
		sudo sed -i "/systemd-journal:/s/$/,$adminGroup/" /etc/group
		grep systemd-journal: /etc/group
	fi
fi | tee $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log
