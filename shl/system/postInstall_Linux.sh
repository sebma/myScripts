#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	sudo=""
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	sudo=sudo
	isDebianLike=true
fi

test $(id -u) == 0 && sudo=""

mtu=9000
proxyIP=X.Y.Z.T4
NTP1=X.Y.Z.T1
NTP2=X.Y.Z.T2
http_proxy_port=80
http_proxy=http://$proxyIP:$http_proxy_port
https_proxy=$http_proxy/HTTPS///
if   $isRedHatLike;then
	timedatectl status | grep Time.zone:.Europe/Paris -q || timedatectl set-timezone Europe/Paris
	localectl set-keymap fr
	localectl set-x11-keymap fr
	localectl set-locale en_GB.utf8
	hostnamectl status
	grep ^proxy\s*= /etc/yum.conf -q || echo proxy = $http_proxy | tee -a /etc/yum.conf
	yum clean expire-cache
	systemctl stop NetworkManager
	systemctl disable NetworkManager
	systemctl mask NetworkManager
	grep ^MTU= /etc/sysconfig/network-scripts/ifcfg-bond0 -q || echo MTU=$mtu | tee -a /etc/sysconfig/network-scripts/ifcfg-bond0
	grep ^USERCTL= /etc/sysconfig/network-scripts/ifcfg-bond0 -q || echo USERCTL=no | tee -a /etc/sysconfig/network-scripts/ifcfg-bond0
	grep ^NM_CONTROLLED= /etc/sysconfig/network-scripts/ifcfg-bond0 -q || sed -i "s/NM_CONTROLLED=.*/NM_CONTROLLED=no/" /etc/sysconfig/network-scripts/ifcfg-bond0
	grep ^ONBOOT= /etc/sysconfig/network-scripts/ifcfg-bond0 -q || sed -i "s/ONBOOT=.*/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-bond0
	grep ^BOOTPROTO=dhcp /etc/sysconfig/network-scripts/ifcfg-bond0 -q || sed -i "s/BOOTPROTO=.*/BOOTPROTO=none/" /etc/sysconfig/network-scripts/ifcfg-bond0
	grep NOZEROCONF /etc/sysconfig/network -q || echo NOZEROCONF=yes | tee -a /etc/sysconfig/network # Disable APIPA
	systemctl restart network

	# CONF NTP (hors systemd)
	yum install -y ntp
	# sed -i '/^server /s/server.*/server $NTP1 iburst/;0' /etc/ntp.conf
	# sed -i '/^server /s/server.*/server $NTP2 iburst/;0' /etc/ntp.conf
	systemctl stop ntpd && time ntpdate $NTP1 # Commande a tester AVANT de demarrer le service
	systemctl restart ntpd

	# CONF SNMP
	sudo systemctl start snmpd
	ss -nul | grep :161
	$sudo yum install -y net-snmp net-snmp-utils net-snmp-devel
	if ! grep rouser.svc_snmp /etc/snmp/snmpd.conf -q;then
		$sudo systemctl stop snmpd;$sudo net-snmp-create-v3-user -ro -X AES -A MD5 svc_snmp # Les MDPs sont a saisir de maniere interactive
		$sudo systemctl restart snmpd
	fi
	$sudo egrep "^(rouser|createUser|usmUser)" /var/lib/net-snmp/snmpd.conf /etc/snmp/snmpd.conf

	systemctl stop firewalld; systemctl disable firewalld;systemctl mask firewalld;yum remove firewalld firewalld-filesystem # Car firewalld coupe les flux SNMP
	systemctl daemon-reload
	# OU ALORS AUTORISER LE SNMP :
	firewall-cmd --zone=public --add-port=161/udp --permanent
	firewall-cmd --zone=public --add-port=161/tcp --permanent
	firewall-cmd --zone=public --add-port=162/udp --permanent
	firewall-cmd --zone=public --add-port=162/tcp --permanent
	firewall-cmd --reload

	# snmpwalk -v1 -c public X.Y.Z.T system
	snmpwalk -v2c -c MPPREAD X.Y.Z.T system
#	MDP_SNMP=q37uYXFqhy27eQeM97C7
	snmpwalk -v3 -A $MDP_SNMP -l authNoPriv -u svc_snmp -a MD5 X.Y.Z.T system

	firstIPAddress=$(ip -o a | awk -F " +|/" '!/lo /&&!/inet6/{print$4;exit}')
	snmpget -v3 -u svc_snmp -l authNoPriv -A $MDP_SNMP $firstIPAddress sysName.0 hrSystemDate.0 sysUpTimeInstance sysLocation.0 sysContact.0 sysDescr.0


	# INSTALL DE PAQUETS
	yum install ca-certificates ncdu
	yum install bash-completion yum-utils psmisc lsof nano gpm traceroute pciutils usbutils bind-utils vim-enhanced curl gawk wget lshw bc units lsscsi screen rsync mc parted gdisk mlocate -y
	yum install epel-release -y # EPEL REPO
	yum install glances smem jq lnav pv xclip xsel -y # FROM EPEL REPO
	yum install btop htop -y # FROM EPEL REPO
	yum install sysstat -y && systemctl start sysstat
	systemctl -at service | grep glances -q && $sudo systemctl stop glances && $sudo systemctl disable glances && $sudo systemctl mask glances
	systemctl -at service | grep gpm -q && $sudo systemctl stop gpm && $sudo systemctl disable gpm

	# CONF RSYSLOG HORS SERVEURS SCALITY
	syslogSERVER=X.Y.Z.T3
	grep $syslogSERVER /etc/rsyslog.conf /etc/rsyslog.d/* -q || echo "*.* @$syslogSERVER" | $sudo tee -a /etc/rsyslog.d/pluriad-rsyslog.conf
	$sudo systemctl restart rsyslog

	if grep -i virtual /sys/class/dmi/id/product_name -q;then
		rpm -q open-vm-tools | grep open-vm-tools -q || yum install open-vm-tools -y
		$sudo systemctl start vmtoolsd
	fi

######## INSTALLATION DU FUSIONINVENTORY-AGENT ######## FROM THE EPEL REPO
	yum install fusioninventory-agent{,-yum-plugin,-task-{collect,deploy,esx,inventory,network}} -y

######## FIREWALLING ########
	iptables -F # Pour flusher les regles de filtrage
	iptables -X # Pour supprimer toutes les chaines
	iptables -L
	systemctl restart firewalld
	firewall-cmd --state
	firewall-cmd --list-all

elif $isDebianLike;then
	#aptSimul="-s"
	apt="$(which apt) -V"
	$sudo ufw allow 22
	timedatectl status | grep Time.zone:.Europe/Paris -q || $sudo timedatectl set-timezone Europe/Paris
	grep ^Acquire.*$http_proxy /etc/apt/apt.conf.d/*proxy -q || $sudo cat <<-EOF | sudo tee /etc/apt/apt.conf.d/90curtin-aptproxy
		Acquire::http::proxy "$http_proxy";
		#Acquire::https::proxy "$https_proxy";
EOF
	if : < /dev/tcp/$proxyIP/http;then
		$sudo $apt update
		$sudo $apt upgrade -y $aptSimul
		if grep -i virtual /sys/class/dmi/id/product_name -q;then
			dpkg -s open-vm-tools | grep installed -q || $sudo $apt install open-vm-tools -y $aptSimul
			$sudo systemctl start vmtoolsd
		fi

######## INSTALLATION DU FUSIONINVENTORY-AGENT ########
#		$sudo $apt install fusioninventory-agent{,-task-{collect,deploy,esx,network}} # STAND-BY car GLPIv10
#		grep "^server = .*helpdesk" /etc/fusioninventory/agent.cfg -q || $sudo sed -r -i".ORIG" 's/.*httpd-trust.*/httpd-trust = 127.0.0.1\/32,X.Y.Z.T/;0,/server.*=/s|^#?server =.*|server = https://helpdesk.media-participations.com/plugins/fusioninventory/|;' /etc/fusioninventory/agent.cfg
#		$sudo systemctl restart fusioninventory-agent.service

		$sudo $apt install ca-certificates
		$sudo update-ca-certificates --fresh
		$sudo $apt install debsecan ncdu vim curl gawk wget jq lshw bc units lsscsi htop pv screen rsync mc parted gdisk -y
		$sudo $apt install dfc apt-file dlocate psmisc lsof plocate fd-find landscape-common ipcalc xclip xsel -y
		$sudo $apt install glances smem -y
		$sudo $apt install ethtool gpm
		$sudo $apt install sysstat
		dpkg -l sysstat && $sudo dpkg-reconfigure sysstat
		dpkg -s gpm | grep installed -q && systemctl -at service | grep gpm -q && $sudo systemctl stop gpm && $sudo systemctl disable gpm
		dpkg -s glances | grep installed -q && systemctl -at service | grep glances -q && $sudo systemctl stop glances && $sudo systemctl disable glances

		if [ $distribID == ubuntu ];then
			$sudo rm -fv /var/lib/ubuntu-release-upgrader/release-upgrade-available
			test -n "$http_proxy" && $sudo sed -i.orig "s|https://|$https_proxy|" /etc/update-manager/meta-release
			$sudo /usr/lib/ubuntu-release-upgrader/release-upgrade-motd
			timeout 5s /usr/lib/ubuntu-release-upgrader/check-new-release
		fi

		# CONFIG GRUB
		grep GRUB_TIMEOUT_STYLE=hidden /etc/default/grub -q && $sudo sed -i.orig "s/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/;s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/" /etc/default/grub
		$sudo update-grub

		# CONFIG SNMP
		$sudo $apt install snmp snmpd -y $aptSimul # Pour la supervision SNMP
		$sudo $apt install snmp-mibs-downloader -y $aptSimul # Necessaire depuis Ubuntu 12.04 cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/
		$sudo systemctl stop snmpd;$sudo net-snmp-create-v3-user -ro -X AES -A MD5 svc_snmp # Les MDPs sont a saisir de maniere interactive

		grep ^mibs /etc/snmp/snmp.conf -q && $sudo sed -i 's/\(^mibs.*$\)/#\1/' /etc/snmp/snmp.conf # cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/

		$sudo egrep "^(rouser|createUser|usmUser)" /var/lib/snmp/snmpd.conf /usr/share/snmp/snmpd.conf
		ss -4nul | grep :161
		$sudo grep "^agent[Aa]ddress.*127.0.0.1" /etc/snmp/snmpd.conf -q && $sudo sed -i.orig "s/^agent[Aa]ddress.*/agentAddress udp:161/" /etc/snmp/snmpd.conf
		$sudo grep ^rocommunity /etc/snmp/snmpd.conf -q && $sudo sed -i.orig2 "/^rocommunity/s/^/#/" /etc/snmp/snmpd.conf # A DEMANDER A MIGUEL POURQUOI
		grep includeAllDisks /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.d/pluriad_snmpd.conf -q  2>/dev/null || echo includeAllDisks 20% | $sudo tee -a /etc/snmp/snmpd.conf.d/pluriad_snmpd.conf
		$sudo systemctl start snmpd
		$sudo ufw allow snmp

#		snmpwalk -v3 -A $MDP_SNMP -l authNoPriv -u svc_snmp localhost | grep -v hrSWRunParameters
#		MDP_SNMP=q37uYXFqhy27eQeM97C7
#		MDP_SNMP_V3=ohqua7ke6Cain6aeb9au
		firstIPAddress=$(ip -o a | awk -F " +|/" '!/lo /&&!/inet6/{print$4;exit}')

#		snmpwalk -v1 -c public $firstIPAddress system
		snmpwalk -v2c -c MPPREAD $firstIPAddress system
		snmpwalk -v3 -A $MDP_SNMP -l authNoPriv -u svc_snmp $firstIPAddress system
		snmpwalk -v3 -A $MDP_SNMP_V3 -l authNoPriv -u svc_snmp_v3 -a SHA-512 $firstIPAddress system

		snmpget -v3 -u svc_snmp -l authNoPriv -A $MDP_SNMP $firstIPAddress sysName.0 hrSystemDate.0 sysUpTimeInstance sysLocation.0 sysContact.0

		# CONFIG NTP
		$sudo apt install -V systemd-timesyncd
		egrep -v "^$|^#" /etc/systemd/timesyncd.conf
		timedatectl show-timesync
		systemctl status systemd-timesyncd
		journalctl -u systemd-timesyncd.service -n 25
		timedatectl status
		$sudo timedatectl set-ntp false; $sudo timedatectl set-ntp true
		$sudo systemctl restart systemd-timesyncd

		# CONF RSYSLOG HORS SERVEURS SCALITY
		syslogSERVER=X.Y.Z.T3
		grep $syslogSERVER /etc/rsyslog.conf /etc/rsyslog.d/* -q || echo "*.* @$syslogSERVER" | $sudo tee -a /etc/rsyslog.d/pluriad-rsyslog.conf
		$sudo systemctl restart rsyslog

		mkdir -p $HOME/.vim
		touch $HOME/.vim/vimrc
		cat > $HOME/.bash_aliases <<-EOF
			# vim: ft=sh noet:
			which fd &>/dev/null && fd_find=fd || { which fdfind &>/dev/null && fd_find=fdfind; }

			alias bc='\bc -l'
			alias cp='\cp -i'
			alias dos2unix="\sed -i 's/\r//'"
			alias errors="egrep -wiC2 'err:|:err|error|erreur|java.*exception'"
			test \$fd_find && alias findBigFiles="findBiggerThan +100mi | sort -rhk5"
			test \$fd_find && alias findBiggerThan='$fd_find -H --xdev -t f -E /dev,/proc,/sys -ls . $PWD -S'
			alias ipinfo='\ip -c -br a'
			alias isUEFI='[ -d /sys/firmware/efi ] && echo '\''Session EFI'\'' || echo '\''Session non-EFI'\'''
			alias journalctlErrors='\journalctl -p emerg..err --no-pager'
			alias l=ls
			alias ll >/dev/null 2>&1 || alias ll='ls -l --color=auto'
			alias llh='ll -h'
			alias ls='ls -F'
			alias lseth='\lspci -nnd::0200'
			alias lsraid='\lspci -nnd::0104'
			alias lssata='\lspci -nnd::0106'
			ls /dev/md* >/dev/null 2>&1 && alias mdraidInfo='sudo mdadm /dev/md?;sudo mdadm -D /dev/md?;cat /proc/mdstat'
			alias mv='\mv -i'
			alias nocomment='\egrep -v "^(\s*#|$|;)"'
			alias od='\od -ct x1z'
			alias psf='\ps -O user:14,euid,ppid,pcpu,pmem,start'
			alias psu='psf -u $USER'
			alias ramSize="awk '/MemTotal/{print \\\$2*1024}' /proc/meminfo | numfmt --to=iec-i --suffix=B"
			alias rm='\rm -i'
			alias sdiff='\sdiff -Ww \$COLUMNS'
			alias sudo='\sudo '
			alias sysInfo='\cat /sys/class/dmi/id/product_name'
			alias vi='vim'
			alias view='vim -R'
EOF
	fi
fi
