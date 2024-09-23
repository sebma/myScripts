#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi

scriptBaseName=${0/*\//}
if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

#aptSimul="-s"

apt="$(which apt) -V"
if $isDebianLike;then
	test $(id -u) == 0 && sudo="" || sudo=sudo
	# CONFIG du Swap
	vgOS=$(findmnt / -n -o source | awk -F '[/-]' '{print$4}')
	grep /dev/$vgOS/swap /etc/fstab -q || echo -e "/dev/$vgOS/swap\tnone\tswap\tsw\t0\t0" | sudo tee -a /etc/fstab # Ajout du "swap" dans le /etc/fstab

	$sudo sysctl -w kernel.dmesg_restrict=0 # Allows users to run "dmesg"
	echo kernel.dmesg_restrict=0 | sudo tee -a /etc/sysctl.d/99-$company.conf
	$sudo systemctl restart systemd-sysctl.service

	# CONFIG UFW
	$sudo sed -i "s/IPV6.*/IPV6=no/" /etc/default/ufw
	$sudo ufw reload
#	$sudo ufw allow OpenSSH || $sudo ufw allow ssh
	$sudo ufw allow 1022/tcp comment "do-release-upgrade alternate SSH port"
	$sudo ufw allow 62354/tcp comment "GLPI-Agent"
	$sudo ufw allow 2002/tcp comment "LogMeIn Host"
	localNetwork=$(ip -4 route | awk "/^[0-9].*dev $(ip -4 route | awk '/default/{print$5}')/"'{print$1}')
	$sudo ufw allow from $localNetwork to any app OpenSSH
	$sudo ufw allow from $bastion to any app OpenSSH

	wanIP=$(dig -4 +short @resolver1.opendns.com A myip.opendns.com)
	sudo ufw allow from $wanIP to any port 1022 proto tcp comment "do-release-upgrade alternate SSH port"
#	sudo ufw allow "Nginx HTTPS"

	grep "preserve_hostname: true" /etc/cloud/cloud.cfg -q && sudo sed -i "s/preserve_hostname: true/preserve_hostname: false/" /etc/cloud/cloud.cfg
	sudo touch /etc/cloud/cloud-init.disabled # To Disable Cloud-Init

	timedatectl status | grep Time.zone:.Europe/Paris -q || $sudo timedatectl set-timezone Europe/Paris

	# CONFIG KEYBOARD LAYOUT
	localectl set-x11-keymap fr pc105 latin9
	sudo localectl set-keymap fr # Ne marche plus depuis Ubuntu 22.04
	sudo localectl set-locale LANG=en_US.UTF-8

	hostnamectl status

	if : < /dev/tcp/$proxyIP/http;then
		# CONFIG PROXY
		egrep http_proxy= $HOME/.profile -q  || echo -e "\nexport http_proxy=$http_proxy"   >> $HOME/.profile
		egrep https_proxy= $HOME/.profile -q || echo -e "\nexport https_proxy=$https_proxy" >> $HOME/.profile
		# Propagation des variables "http_proxy" et "https_proxy" aux "sudoers"
		sudo grep '^[^#]\s*.*env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"' | sudo tee -a /etc/sudoers.d/proxy

		# man apt-transport-http apt-transport-https
		grep ^Acquire.*$http_proxy /etc/apt/apt.conf.d/*proxy -q  || echo "Acquire::http::proxy  \"$http_proxy\";"  | sudo tee /etc/apt/apt.conf.d/00aptproxy
		grep ^Acquire.*$https_proxy /etc/apt/apt.conf.d/*proxy -q || echo "Acquire::https::proxy \"$https_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/00aptproxy

		$sudo $apt update
		$sudo $apt upgrade -y $aptSimul

		# CONFIG SNAPD
		$sudo snap get system proxy.http  || $sudo snap set system proxy.http=$http_proxy
		$sudo snap get system proxy.https || $sudo snap set system proxy.https=$https_proxy
		sudo snap get system proxy
		snap debug connectivity

		# CONFIG GIT
		git config --global http.proxy  $http_proxy
		git config --global https.proxy $https_proxy
		git config --global -l | egrep https?.proxy

		# CONFIG DNS
		resolvectl status $iface

		if ! resolvectl dns | grep "$DNS_SERVER1" -q;then
			iface=$(\ls /sys/class/net/ | grep -vw lo)
			$sudo resolvectl dns $iface $DNS_SERVER1 $FallBack_DNS_SERVER
			$sudo resolvectl domain $iface $DOMAIN
			resolvectl dns $iface
			resolvectl status $iface
		fi

		# Install open-vm-tools
		grep -i virtual /sys/class/dmi/id/product_name -q && ! dpkg -s open-vm-tools 2>/dev/null | grep installed -q && $sudo $apt install open-vm-tools -y $aptSimul
		$sudo systemctl start vmtoolsd

		if [ $distribID == ubuntu ];then
			test -n "$http_proxy" && $sudo sed -i.orig "s|https://|http://|" /etc/update-manager/meta-release
			$sudo rm -fv /var/lib/ubuntu-release-upgrader/release-upgrade-available
			$sudo /usr/lib/ubuntu-release-upgrader/release-upgrade-motd
			timeout 5s /usr/lib/ubuntu-release-upgrader/check-new-release;echo $? # FLUX http-proxy a ouvrir vers $http_proxy
		fi

		$sudo $apt install ca-certificates
		sudo update-ca-certificates --fresh
		ll /etc/ssl/certs/ | grep Gandi

		$sudo $apt install net-tools -y $aptSimul # Pour netstat
		$sudo $apt install ugrep btop plocate gh fd-find # UBUNTU >= 22.04
		$sudo $apt install landscape-common # cf. https://github.com/canonical/landscape-client/blob/master/debian/landscape-common.install
		$sudo $apt install ca-certificates debsecan ncdu ripgrep silversearcher-ag ack progress gcp shellcheck command-not-found nmon smartmontools iotop lsof net-tools pwgen ethtool smem sysstat fzf grep gawk sed curl remake wget jq jid vim dfc lshw screenfetch bc units lsscsi jq btop htop apt-file dlocate pv screen rsync x11-apps mc landscape-common parted gdisk ipcalc -y

		# $sudo $apt install -t $(lsb_release -sc)-backports smartmontools # On debian 10
		egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q || $sudo update-smart-drivedb -u github

		# CONFIG SYSSTAT
		if dpkg -l | grep sysstat -q;then
			debconf-show sysstat 2>/dev/null | grep sysstat/enable
			# $sudo debconf-set-selections <<< "sysstat sysstat/enable boolean true" # get overwritten by the ENABLED parameter in /etc/default/sysstat
			$sudo sed -i.ORIG 's/^ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
			$sudo dpkg-reconfigure sysstat -f noninteractive # pour le bon fonctionnement de l'outil "sar"
			debconf-show sysstat 2>/dev/null | grep sysstat/enable
		fi

		$sudo $apt install gpm
		dpkg -s gpm | grep installed -q && systemctl -at service | grep gpm -q && sudo systemctl stop gpm && sudo systemctl disable gpm
		$sudo apt install glances && dpkg -s glances | grep installed -q && systemctl -at service | grep glances -q && sudo systemctl stop glances && sudo systemctl disable glances

		if systemctl list-unit-files | grep cloud.*enabled.*enabled -q;then
			systemctl list-unit-files | awk '/cloud-init\..*enabled.*enabled/{print$1}' | while read service;do
				$sudo systemctl stop $service
				$sudo systemctl disable $service
				$sudo systemctl mask $service
			done
		fi

		# CONFIG GRUB
#		grep GRUB_TIMEOUT_STYLE=hidden /etc/default/grub -q && $sudo sed -i.ORIG "s/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/;s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=15/" /etc/default/grub
		grep GRUB_TIMEOUT_STYLE=hidden /etc/default/grub /etc/default/grub.d/* -q && echo -e "GRUB_TIMEOUT_STYLE=menu\nGRUB_TIMEOUT=15" | sudo tee -a /etc/default/grub.d/$company-grub.cfg
#		grep '\#GRUB_GFX_MODE=' /etc/default/grub -q && $sudo sed -i.ORIG.2 "s/#GRUB_GFX_MODE=.*/GRUB_GFX_MODE=1152x864/" /etc/default/grub
		grep '\#GRUB_GFX_MODE=' /etc/default/grub /etc/default/grub.d/* -q && echo "GRUB_GFX_MODE=1152x864" | sudo tee -a /etc/default/grub.d/$company-grub.cfg
		$sudo update-grub

		# CONFIG SNMP
		$sudo $apt install snmpd -y $aptSimul # Pour snmpd et net-snmp-create-v3-user
		$sudo $apt install snmp-mibs-downloader -y $aptSimul # Necessaire depuis Ubuntu 12.04 cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/
		$sudo $apt install snmp -y $aptSimul # Pour snmpwalk/snmpget

		ss -4nul | grep :161
		$sudo systemctl stop snmpd
		if which net-snmp-create-v3-user >/dev/null 2>&1;then
			grep rouser.svc_snmp /usr/share/snmp/snmpd.conf -q    || sudo net-snmp-create-v3-user -ro -X AES -A MD5 svc_snmp # Les MDPs sont a saisir de maniere interactive
			grep rouser.svc_snmp_v3 /usr/share/snmp/snmpd.conf -q || sudo net-snmp-create-v3-user -ro -X AES -A SHA-512 svc_snmp_v3 # Les MDPs sont a saisir de maniere interactive
		else
			# For Ubuntu 18.04 and older
			$sudo $apt libsnmp-dev -y $aptSimul # Pour "net-snmp-config"
			MDP_SNMP_V3=ohqua7ke6Cain6aeb9au;MDP_SNMP_ENC_V3=aiChiimeegah8eejaele
#			sudo net-snmp-config --create-snmpv3-user -v3 -ro -A $MDP_SNMP_V3 -X $MDP_SNMP_ENC_V3 -a SHA-512 -x AES svc_snmp_v3
#			sudo net-snmp-create-v3-user -ro -A $MDP_SNMP_V3 -X $MDP_SNMP_ENC_V3 -a SHA-512 -x AES svc_snmp_v3 # On Ubuntu 14.04,16.04
			MDP_SNMP=q37uYXFqhy27eQeM97C7;MDP_SNMP_ENC=8nbU2PuqK327uLSb5P7u
			sudo net-snmp-create-v3-user -ro -A $MDP_SNMP -X $MDP_SNMP_ENC -a MD5 -x AES svc_snmp # Car les algo supportes par le script sur Ubuntu 14.04,16.04,18.04 sont MD5/SHA
		fi
		$sudo egrep "^(rouser|createUser|usmUser)" /var/lib/snmp/snmpd.conf /usr/share/snmp/snmpd.conf 2>/dev/null

		grep ^mibs /etc/snmp/snmp.conf -q && $sudo sed -i '/^mibs.*$/s/^/#/' /etc/snmp/snmp.conf # cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/

		if test -f /etc/snmp/snmpd.conf;then
			$sudo grep "^agent[Aa]ddress.*127.0.0.1" /etc/snmp/snmpd.conf -q && $sudo sed -i.orig "/^agent[Aa]ddress.*/s/^/#/" /etc/snmp/snmpd.conf
			$sudo grep ^rocommunity /etc/snmp/snmpd.conf -q && $sudo sed -i.orig2 "/^rocommunity/s/^/#/" /etc/snmp/snmpd.conf
			$sudo mkdir -pv /etc/snmp/snmpd.conf.d/
			$sudo grep includeAllDisks /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.d/$company_snmpd.conf -q  2>/dev/null || echo includeAllDisks 20% | sudo tee -a /etc/snmp/snmpd.conf.d/$company_snmpd.conf
			egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor -q && sudo sed -i.BACKUP "/^sysLocation.*/s/^sysLocation.*/sysLocation    Hosted on our VMware ESX Cluster/" /etc/snmp/snmpd.conf
			$sudo systemctl start snmpd
		fi
		ss -4nul | grep :161

		$sudo ufw allow snmp
		$sudo ufw status numbered

		# CONFIG NTP
		if ! timedatectl status | grep Time.zone:.Europe/Paris -q;then
			$sudo timedatectl set-timezone Europe/Paris
			$sudo dpkg-reconfigure tzdata
		fi

		$sudo $apt purge ntp
		$sudo $apt install systemd-timesyncd

		sudo mkdir -pv /etc/systemd/timesyncd.conf.d/
		echo [Time] | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf
		grep "^NTP=$NTP" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "NTP=$NTP" | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf
		grep "^FallbackNTP=$FallbackNTP" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "FallbackNTP=$FallbackNTP" | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf
		RootDistanceMaxSec=20
		grep "^RootDistanceMaxSec=$RootDistanceMaxSec" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "RootDistanceMaxSec=$RootDistanceMaxSec" | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf

		$sudo systemctl restart systemd-timesyncd
		$sudo timedatectl set-ntp false; sudo timedatectl set-ntp true # Relance une synchro NTP
		timedatectl timesync-status # A partir de Ubuntu 20.04
		timedatectl status
		timedatectl show
		timedatectl show-timesync

		egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q || $sudo hwclock --systohc

		# CONFIG SYSLOG
		grep $syslogSERVER /etc/rsyslog.conf /etc/rsyslog.d/* -q || echo "*.* @$syslogSERVER" | sudo tee -a /etc/rsyslog.d/$company-rsyslog.conf
		$sudo systemctl restart rsyslog

		mkdir -p $HOME/.vim
		touch $HOME/.vim/vimrc
		$sudo mkdir -p /root/.vim
		$sudo touch /root/.vim/vimrc
	fi
fi
