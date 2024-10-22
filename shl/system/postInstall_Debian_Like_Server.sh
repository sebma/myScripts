#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)

if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	if echo $distribID | egrep "ubuntu" -q;then
		isUbuntuLike=true
	fi
fi

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

apt="$(which apt) -V"
aptOtions="-V"
aptSimul="-s"
if $isDebianLike;then
	test $(id -u) == 0 && sudo="" || sudo=sudo

	# DESACTIVER l'IPv6 ("link-local: []") AVEC yq : WIP
	# AJOUT L'OPTION "optional: true" AVEC yq : WIP

	# ACTIVATION DE dmesg
	sysctl kernel.dmesg_restrict || grep "kernel.dmesg_restrict\s*=\s*0" -q || $sudo sysctl -w kernel.dmesg_restrict=0 # Allows users to run "dmesg"
	grep "kernel.dmesg_restrict\s*=\s*0" /etc/sysctl.conf /etc/sysctl.d/*.conf -q || {
		echo kernel.dmesg_restrict=0 | sudo tee -a /etc/sysctl.d/99-$company.conf
		$sudo systemctl restart systemd-sysctl.service
	}

	grep "preserve_hostname: true" /etc/cloud/cloud.cfg -q && sudo sed -i "s/preserve_hostname: true/preserve_hostname: false/" /etc/cloud/cloud.cfg
	sudo touch /etc/cloud/cloud-init.disabled # To Disable Cloud-Init

	timedatectl status | grep Time.zone:.Europe/Paris -q || $sudo timedatectl set-timezone Europe/Paris

	# CONFIG KEYBOARD LAYOUT
	localectl set-x11-keymap fr pc105 latin9
	$isUbuntuLike && [ $majorNumber -le 20 ] && sudo localectl set-keymap fr # Ne marche plus depuis Ubuntu 22.04
	sudo localectl set-locale LANG=en_US.UTF-8

	hostnamectl status
	hostnamectl chassis 2>/dev/null || hostnamectl status | awk '/Chassis/{print$2}'

	proxyIP=$(echo $http_proxy | sed "s,https\?://\|:[0-9]*,,g")
	if : < /dev/tcp/$proxyIP/http;then
		# CONFIG PROXY
#		egrep http_proxy= $HOME/.profile -q  || echo -e "\nexport http_proxy=$http_proxy"   >> $HOME/.profile
#		egrep https_proxy= $HOME/.profile -q || echo -e "\nexport https_proxy=$https_proxy" >> $HOME/.profile
		# Propagation des variables "http_proxy" et "https_proxy" aux "sudoers"
		sudo grep '^[^#]\s*.*env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"' | sudo tee -a /etc/sudoers.d/proxy_env

		# man apt-transport-http apt-transport-https
		grep ^Acquire.*$http_proxy  /etc/apt/apt.conf.d/*aptproxy -q || echo "Acquire::http::proxy  \"$http_proxy\";"  | sudo tee /etc/apt/apt.conf.d/00aptproxy
		grep ^Acquire.*$https_proxy /etc/apt/apt.conf.d/*aptproxy -q || echo "Acquire::https::proxy \"$https_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/00aptproxy

		$sudo apt update

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
		if ! resolvectl dns | grep "$DNS_SERVER1" -q;then
			iface=$(\ls /sys/class/net/ | grep -vw lo)
			resolvectl status $iface
			$sudo resolvectl dns $iface $DNS_SERVER1 $FallBack_DNS_SERVER
			$sudo resolvectl domain $iface $searchDOMAIN
			resolvectl dns $iface
			resolvectl status $iface
		fi

		# Install open-vm-tools
		grep -i virtual /sys/class/dmi/id/product_name -q && ! dpkg -s open-vm-tools 2>/dev/null | grep installed -q && $sudo $apt install open-vm-tools -y
		$sudo systemctl start vmtoolsd

		architecture=$(dpkg --print-architecture)
		if ! dpkg -s dra >/dev/null;then
			https_proxy=$https_proxy wget -c -nv https://github.com/devmatteini/dra/releases/latest/download/dra_0.6.2-1_$architecture.deb
			sudo apt install -V ./dra_0.6.2-1_$architecture.deb
			rm ./dra_0.6.2-1_$architecture.deb
		fi

		if which dra &>/dev/null;then
			which yq &>/dev/null || http_proxy=$http_proxy dra download -a mikefarah/yq -I yq_linux_$architecture
			sudo install -vpm 755 ./yq_linux_$architecture /usr/local/bin/yq
			rm -y ./yq_linux_$architecture
		fi

		$sudo $apt install ca-certificates apt-transport-https
		sudo update-ca-certificates --fresh
		ls -l /etc/ssl/certs/ | grep Gandi

		$sudo $apt install net-tools -y # Pour netstat
		$isUbuntuLike && [ $majorNumber -ge 22 ] && $sudo $apt install ugrep btop plocate gh fd-find # UBUNTU >= 22.04
		$sudo $apt install sockstat landscape-common # cf. https://github.com/canonical/landscape-client/blob/master/debian/landscape-common.install
		$sudo $apt install ca-certificates debsecan ncdu ripgrep silversearcher-ag ack progress gcp shellcheck command-not-found nmon smartmontools iotop lsof net-tools pwgen ethtool smem sysstat fzf grep gawk sed curl remake wget jq jid vim dfc lshw screenfetch bc units lsscsi jq btop htop apt-file dlocate pv screen rsync x11-apps mc landscape-common parted gdisk ipcalc aptitude aria2 hub lynx ppa-purge rclone w3m w3m-img xclip xsel -y

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
		$sudo apt install glances -V && dpkg -s glances | grep installed -q && systemctl -at service | grep glances -q && sudo systemctl stop glances && sudo systemctl disable glances

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
		grep ^GRUB_RECORDFAIL_TIMEOUT= /etc/default/grub /etc/default/grub.d/* -q && || echo 'GRUB_RECORDFAIL_TIMEOUT=$GRUB_TIMEOUT' | sudo tee -a /etc/default/grub.d/$company-grub.cfg
#		grep '\#GRUB_GFX_MODE=' /etc/default/grub -q && $sudo sed -i.ORIG.2 "s/#GRUB_GFX_MODE=.*/GRUB_GFX_MODE=1152x864/" /etc/default/grub
		grep '\#GRUB_GFX_MODE=' /etc/default/grub /etc/default/grub.d/* -q && echo "GRUB_GFX_MODE=1152x864" | sudo tee -a /etc/default/grub.d/$company-grub.cfg
		$sudo update-grub

		# CONFIG SNMP
		$sudo $apt install snmpd -V -y # Pour snmpd et net-snmp-create-v3-user
		$sudo $apt install snmp-mibs-downloader -V -y # Necessaire depuis Ubuntu 12.04 cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/
		$sudo $apt install snmp -V -y # Pour snmpwalk/snmpget

		ss -4nul | grep :161
		$sudo systemctl stop snmpd
		if $isUbuntuLike && [ $majorNumber -ge 20 ] && which net-snmp-create-v3-user >/dev/null 2>&1;then
			grep rouser.svc_snmp /usr/share/snmp/snmpd.conf -q     || sudo net-snmp-create-v3-user -ro -X AES -A MD5 svc_snmp # Les MDPs sont a saisir de maniere interactive
			grep rouser.svc_coservit /usr/share/snmp/snmpd.conf -q || sudo net-snmp-create-v3-user -ro -X AES -A SHA svc_coservit # Les MDPs sont a saisir de maniere interactive
			grep rouser.svc_snmp_v3 /usr/share/snmp/snmpd.conf -q  || sudo net-snmp-create-v3-user -ro -X AES -A SHA-512 svc_snmp_v3 # Les MDPs sont a saisir de maniere interactive
		else
			# For Ubuntu 18.04 and older
			$sudo $apt libsnmp-dev -y # Pour "net-snmp-config"

#			sudo net-snmp-config --create-snmpv3-user -v3 -ro -A $MDP_SNMP_V3 -X $MDP_SNMP_ENC_V3 -a SHA-512 -x AES svc_snmp_v3
#			sudo net-snmp-create-v3-user -ro -A $MDP_SNMP_V3 -X $MDP_SNMP_ENC_V3 -a SHA-512 -x AES svc_snmp_v3 # On Ubuntu 14.04,16.04

			sudo net-snmp-create-v3-user -ro -A $MDP_SNMP -X $MDP_SNMP_ENC -a MD5 -x AES svc_snmp # Car les algo supportes par le script sur Ubuntu 14.04,16.04,18.04 sont MD5/SHA
		fi
		$sudo egrep "^(rouser|createUser|usmUser)" /var/lib/snmp/snmpd.conf /usr/share/snmp/snmpd.conf 2>/dev/null

		grep ^mibs /etc/snmp/snmp.conf -q && $sudo sed -i '/^mibs.*$/s/^/#/' /etc/snmp/snmp.conf # cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/

		if test -f /etc/snmp/snmpd.conf;then
			$sudo grep "^agent[Aa]ddress.*127.0.0.1" /etc/snmp/snmpd.conf -q && $sudo sed -i.orig "/^agent[Aa]ddress.*/s/^/#/" /etc/snmp/snmpd.conf
			$sudo grep ^rocommunity /etc/snmp/snmpd.conf -q && $sudo sed -i.orig2 "/^rocommunity/s/^/#/" /etc/snmp/snmpd.conf
			$sudo mkdir -pv /etc/snmp/snmpd.conf.d/
			$sudo grep includeAllDisks /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.d/pluriad_snmpd.conf -q  2>/dev/null || echo includeAllDisks 20% | sudo tee -a /etc/snmp/snmpd.conf.d/pluriad_snmpd.conf
			egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor -q && sudo sed -i.BACKUP "/^sysLocation.*/s/^sysLocation.*/sysLocation    Hosted on our VMware ESX Cluster/" /etc/snmp/snmpd.conf
			$sudo systemctl start snmpd
		fi
		ss -4nul | grep :161

		# CONFIG NTP
		if ! timedatectl status | grep Time.zone:.Europe/Paris -q;then
			$sudo timedatectl set-timezone Europe/Paris
			$sudo dpkg-reconfigure tzdata
		fi

		dpkg -s ntp >/dev/null && $sudo $apt purge ntp -y
		dpkg -s systemd-timesyncd >/dev/null || $sudo $apt install systemd-timesyncd -y

		sudo mkdir -pv /etc/systemd/timesyncd.conf.d/
		echo [Time] | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf
		grep "^NTP=$NTP" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "NTP=$NTP" | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf
		grep "^FallbackNTP=$FallbackNTP" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "FallbackNTP=$FallbackNTP" | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf
		RootDistanceMaxSec=20
		grep "^RootDistanceMaxSec=$RootDistanceMaxSec" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "RootDistanceMaxSec=$RootDistanceMaxSec" | sudo tee -a /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf

		$sudo systemctl restart systemd-timesyncd
		$sudo timedatectl set-ntp false; sudo timedatectl set-ntp true # Relance une synchro NTP
		if $isUbuntuLike && [ $majorNumber -ge 20 ];then
			# A partir de Ubuntu 20.04
			timedatectl timesync-status
			timedatectl show
			timedatectl show-timesync
		fi
		timedatectl status

		egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q || $sudo hwclock --systohc

		# CONFIG SYSLOG
		grep $syslogSERVER /etc/rsyslog.conf /etc/rsyslog.d/* -q || echo "*.* @$syslogSERVER" | sudo tee -a /etc/rsyslog.d/$company-rsyslog.conf
		$sudo systemctl restart rsyslog

		mkdir -p $HOME/.vim
		$sudo mkdir -p /root/.vim
	fi
fi
