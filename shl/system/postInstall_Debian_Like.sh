#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false

# sed -i "s/administrateur/admin/g" /etc/passwd /etc/group /etc/shadow; mv /home/administrateur /home/admin
# usermod -l admin -m -d /home/admin administrateur;groupmod -n admin administrateur # https://serverfault.com/a/653514/312306

distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi
test $(id -u) == 0 && sudo="" || sudo=sudo

#aptSimul="-s"
proxyIP=X.Y.Z.T4
http_proxy_port=80
http_proxy=http://$proxyIP:$http_proxy_port
https_proxy=$http_proxy/HTTPS///
apt="$(which apt) -V"
if $isDebianLike;then
	$sudo sysctl -w kernel.dmesg_restrict=0 # Allows users to run "dmesg"
	echo kernel.dmesg_restrict=0 | sudo tee -a /etc/sysctl.d/99-pluriad.conf
	$sudo systemctl restart systemd-sysctl.service
	$sudo ufw allow ssh

	if : < /dev/tcp/$proxyIP/http;then
		# CONFIG PROXY
		# man apt-transport-http
		grep ^Acquire.*$http_proxy /etc/apt/apt.conf.d/*proxy -q || $sudo cat <<-EOF | sudo tee /etc/apt/apt.conf.d/00aptproxy
			Acquire::http::proxy "$http_proxy";
			Acquire::http::proxy "$http_proxy/HTTPS///";
EOF
		$sudo $apt update
		$sudo $apt upgrade -y $aptSimul

		# DNS
		resolvectl status
		DNS_SERVER1=X.Y.Z.T1
		FallBack_DNS_SERVER=X.Y.Z.T2
		if ! resolvectl dns | grep "$DNS_SERVER1" -q;then
			iface=$(\ls /sys/class/net/ | grep -vw lo)
			$sudo resolvectl dns $iface $DNS_SERVER1 $FallBack_DNS_SERVER
			resolvectl dns $iface
			resolvectl status $iface
		fi

		# Install open-vm-tools
		grep -i virtual /sys/class/dmi/id/product_name -q && ! dpkg -s open-vm-tools 2>/dev/null | grep installed -q && $sudo $apt install open-vm-tools -y $aptSimul
		$sudo systemctl start vmtoolsd

		if [ $distribID == ubuntu ];then
			test -n "$http_proxy" && $sudo sed -i.orig "s|https://|$https_proxy|" /etc/update-manager/meta-release
			$sudo rm -fv /var/lib/ubuntu-release-upgrader/release-upgrade-available
			$sudo /usr/lib/ubuntu-release-upgrader/release-upgrade-motd
			timeout 5s /usr/lib/ubuntu-release-upgrader/check-new-release;echo $? # FLUX http-proxy a ouvrir vers X.Y.Z.T4
		fi

		$sudo apt -V install ca-certificates
		sudo update-ca-certificates --fresh
		ll /etc/ssl/certs/ | grep Gandi

		$sudo apt net-tools -y $aptSimul # Pour netstat
		$sudo apt -V install ugrep btop plocate gh fd-find # UBUNTU >= 22.04
		$sudo apt -V install landscape-common # cf. https://github.com/canonical/landscape-client/blob/master/debian/landscape-common.install
		$sudo apt -V install ca-certificates debsecan ncdu ripgrep silversearcher-ag ack progress gcp shellcheck command-not-found nmon smartmontools iotop lsof net-tools pwgen ethtool smem sysstat fzf grep gawk sed curl remake wget jq jid vim dfc lshw screenfetch bc units lsscsi jq btop htop apt-file dlocate pv screen rsync x11-apps mc landscape-common parted gdisk ipcalc -y

		# $sudo apt install -t $(lsb_release -sc)-backports smartmontools -V # On debian 10
		$sudo update-smart-drivedb -u github

		if dpkg -l | grep sysstat -q;then
			debconf-show sysstat 2>/dev/null | grep sysstat/enable
			# $sudo debconf-set-selections <<< "sysstat sysstat/enable boolean true" # get overwritten by the ENABLED parameter in /etc/default/sysstat
			$sudo sed -i 's/^ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
			$sudo dpkg-reconfigure sysstat -f noninteractive # pour le bon fonctionnement de l'outil "sar"
			debconf-show sysstat 2>/dev/null | grep sysstat/enable
		fi

		$sudo $apt install gpm
		dpkg -s gpm | grep installed -q && systemctl -at service | grep gpm -q && sudo systemctl stop gpm && sudo systemctl disable gpm
		$sudo apt install glances -Vy && dpkg -s glances | grep installed -q && systemctl -at service | grep glances -q && sudo systemctl stop glances && sudo systemctl disable glances

		if systemctl list-unit-files | grep cloud.*enabled.*enabled -q;then
			systemctl list-unit-files | awk '/cloud-init\..*enabled.*enabled/{print$1}' | while read service;do
				$sudo systemctl stop $service
				$sudo systemctl mask $service
			done
		fi

		# CONFIG GRUB
		grep GRUB_TIMEOUT_STYLE=hidden /etc/default/grub -q && $sudo sed -i.orig "s/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/;s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=15/" /etc/default/grub
		$sudo update-grub

		# CONFIG SNMP
		$sudo apt install snmp snmpd -y $aptSimul 
		$sudo apt install snmp-mibs-downloader -y $aptSimul # Necessaire depuis Ubuntu 12.04 cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/

		ss -4nul | grep :161
		$sudo systemctl stop snmpd
		if which net-snmp-create-v3-user >/dev/null 2>&1;then
			grep rouser.svc_snmp /usr/share/snmp/snmpd.conf -q    || sudo net-snmp-create-v3-user -ro -X AES -A MD5 svc_snmp # Les MDPs sont a saisir de maniere interactive
			grep rouser.svc_snmp_v3 /usr/share/snmp/snmpd.conf -q || sudo net-snmp-create-v3-user -ro -X AES -A SHA-512 svc_snmp_v3 # Les MDPs sont a saisir de maniere interactive
		else
  			$sudo apt libsnmp-dev -y $aptSimul # Pour "net-snmp-config"
			# For Ubuntu XY.04 and older
			MDP_SNMP_V3=ohqua7ke6Cain6aeb9au;MDP_SNMP_ENC_V3=aiChiimeegah8eejaele
#			sudo net-snmp-config --create-snmpv3-user -v3 -ro -A $MDP_SNMP_V3 -X $MDP_SNMP_ENC_V3 -a SHA-512 -x AES svc_snmp_v3
#			sudo net-snmp-create-v3-user -ro -A $MDP_SNMP_V3 -X $MDP_SNMP_ENC_V3 -a SHA-512 -x AES svc_snmp_v3 # On Ubuntu 14.04,16.04
			MDP_SNMP=q37uYXFqhy27eQeM97C7;MDP_SNMP_ENC=8nbU2PuqK327uLSb5P7u
			sudo net-snmp-create-v3-user -ro -A $MDP_SNMP -X $MDP_SNMP_ENC -a MD5 -x AES svc_snmp # Car les algo supportes par le script sur Ubuntu 14.04,16.04 sont MD5/SHA
		fi
		$sudo egrep "^(rouser|createUser|usmUser)" /var/lib/snmp/snmpd.conf /usr/share/snmp/snmpd.conf

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

		$sudo ufw allow snmp

#		MDP_SNMP=q37uYXFqhy27eQeM97C7
#		MDP_SNMP_V3=ohqua7ke6Cain6aeb9au
#		MDP_SNMP_V3_ESX=bRoj6aLuUO9tVGnNAzkk
		firstIPAddress=$(ip -o a | awk -F " +|/" '!/lo /&&!/inet6/{print$4;exit}')

#		time snmpwalk -v3 -A $MDP_SNMP -l authNoPriv -u svc_snmp $firstIPAddress | grep -v hrSWRunParameters
		time snmpwalk -v3 -A $MDP_SNMP -l authNoPriv -u svc_snmp localhost | grep -i sysName.0
		time snmpwalk -v3 -A $MDP_SNMP_V3 -l authNoPriv -u svc_snmp_v3 localhost | grep -i sysName.0

#		snmpwalk -v1 -c public $firstIPAddress system
		snmpwalk -v2c -c MPPREAD $firstIPAddress system
		snmpwalk -v3 -A $MDP_SNMP -l authNoPriv -u svc_snmp $firstIPAddress system
		snmpwalk -v3 -A $MDP_SNMP_V3 -l authNoPriv -u svc_snmp_v3 -a SHA-512 $firstIPAddress system
		snmpwalk -v3 -A $MDP_SNMP_V3_ESX -l authNoPriv -u svc_snmp_esx -a SHA $firstIPAddress system

		snmpget -v3 -u svc_snmp -l authNoPriv -a MD5 -A $MDP_SNMP localhost sysName.0 hrSystemDate.0 sysUpTimeInstance sysLocation.0 sysContact.0 sysDescr.0
		snmpget -v3 -u svc_snmp_v3 -l authNoPriv -a SHA-512 -A $MDP_SNMP_V3 $firstIPAddress sysName.0 hrSystemDate.0 sysUpTimeInstance sysLocation.0 sysContact.0 sysDescr.0

		# CONFIG NTP
		NTP_SERVER1=X.Y.Z.T1
		FALLBACK_NTP=X.Y.Z.T2
		RootDistanceMaxSec=20
		$sudo apt purge -V ntp
		$sudo apt install -V ntpdate systemd-timesyncd
		timedatectl status | grep Time.zone:.Europe/Paris -q || $sudo timedatectl set-timezone Europe/Paris
		egrep -v "^$|^#" /etc/systemd/timesyncd.conf
		grep "^NTP=$NTP_SERVER1" /etc/systemd/timesyncd.conf -q || $sudo sed -i 's/^#\?NTP=.*/NTP='"$NTP_SERVER1/" /etc/systemd/timesyncd.conf
		grep "^FallbackNTP=$FALLBACK_NTP" /etc/systemd/timesyncd.conf -q || $sudo sed -i 's/^#\?FallbackNTP=.*/FallbackNTP='"$FALLBACK_NTP/" /etc/systemd/timesyncd.conf
		grep "^RootDistanceMaxSec=$RootDistanceMaxSec" /etc/systemd/timesyncd.conf -q || $sudo sed -i 's/^#\?RootDistanceMaxSec=.*/RootDistanceMaxSec='"$RootDistanceMaxSec/" /etc/systemd/timesyncd.conf
		$sudo timedatectl set-ntp false; $sudo timedatectl set-ntp true

		$sudo systemctl restart systemd-timesyncd
		timedatectl timesync-status
		timedatectl status

		time sudo ntpdate $NTP_SERVER1
		egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q || $sudo hwclock --systohc

		# CONFIG SYSLOG
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
			alias journalctlErrors='\journalctl -p emerg..err --no-pager'
			alias l=ls
			alias ll >/dev/null 2>&1 || alias ll='ls -l --color=auto'
			alias llh='ll -h'
			alias ls='ls -F'
			alias lseth='\lspci -nnd::0200'
			alias lsraid='\lspci -nnd::0104'
			alias lssata='\lspci -nnd::0106'
			ls /dev/md* >/dev/null 2>&1 && alias mdraidInfo='sudo mdadm /dev/md?;sudo mdadm -D /dev/md?;cat /proc/mdstat'
			alias manSearch='manpageSearch'
			alias manpageSearch='\man -w -K'
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
