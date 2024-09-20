#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if ! which adcli &>/dev/null;then
	echo "==> Installing realmd adcli krb5-user krb5-doc ..."
	sudo apt-get install realmd adcli krb5-user krb5-doc -y
fi

NAME=$(source /etc/os-release;echo $NAME)
VERSION_ID=$(source /etc/os-release;echo $VERSION_ID)

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

domainLowercase=${domain,,}
domainUppercase=${domain^^}

logDIR=../log
mkdir -p $logDIR

echo "=> The hostname is : " $(hostnamectl hostname)
hostnamectl hostname | grep -i $domain -q || sudo hostnamectl hostname $HOSTNAME.$domainLowercase
echo "=> The hostname is now : " $(hostnamectl hostname)

echo "=> Test de jonction au domain $domainLowercase ..." | tee $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log
if ! sudo adcli testjoin >/dev/null;then
	echo "=> Jonction au domain $domainLowercase ..."
	read -p "=> Veillez saisir votre identifiant T2: " t2USER
	sudo realm join -v --user=$t2USER --computer-ou="$OU" --os-name=$NAME --os-version=$VERSION_ID $domainLowercase
fi 2>&1 | tee -a $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log

if sudo adcli testjoin >/dev/null;then
	if ! grep "renew_lifetime\s*=\s*7d" /etc/krb5.conf -q;then
		echo "renew_lifetime = 7d" | sudo tee -a /etc/krb5.conf >/dev/null
	fi

	echo "=> Parametrage du homedir SSSD en /home/$domainLowercase ..."
	sudo grep "_homedir.*/home/%d/%u$" /etc/sssd/sssd.conf -q || sudo sed -i-$(date +%Y%m%d-%H%M%S).conf "/_homedir/s|=.*|= /home/%d/%u|" /etc/sssd/sssd.conf
	sudo sed -i 's/use_fully_qualified_names.*[Ff]alse/use_fully_qualified_names = True/' /etc/sssd/sssd.conf
	sudo pam-auth-update --enable mkhomedir # Au cas ou le homedir n'est pas cree

	if ! sudo grep "ad_access_filter" /etc/sssd/sssd.conf -q;then
#		echo "=> Ajout du group autorisee dans /etc/sssd/sssd.conf ..."
#		echo "ad_access_filter = (memberOf:1.2.840.113556.1.4.1941:=$allowedGroupsDN)" | sudo tee -a /etc/sssd/sssd.conf # Pour autoriser les membres du groupe $allowedGroupsDN a s_authentifier
		:
	fi

	if ! sudo grep -i "$adminGroup.*ALL=" /etc/sudoers /etc/sudoers.d/* -q;then
		echo "=> Ajout de $adminGroup dans les /etc/sudoers.d/ ..."
		echo "%$adminGroup@$domainLowercase ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers.d/$company
		sudo chmod 440 /etc/sudoers.d/$company
	fi

	groups | grep adm -wq || sudo adduser $USER adm
	if ! grep -i adm:.*$adminGroup /etc/group -q;then
		sudo sed -i "/adm:/s/$/,$adminGroup@$domainLowercase/" /etc/group
		grep adm: /etc/group
	fi

	groups | grep systemd-journal -wq || sudo adduser $USER systemd-journal
	if ! grep -i systemd-journal:.*$adminGroup /etc/group -q;then
		sudo sed -i "/systemd-journal:/s/$/,$adminGroup@$domainLowercase/" /etc/group
		grep systemd-journal: /etc/group
	fi
	sudo systemctl restart sssd
fi 2>&1 | tee -a $logDIR/$HOSTNAME-join-$(date +%Y%m%d).log
