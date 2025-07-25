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

export http_proxy=http://$proxyIP:$http_proxy_port
export https_proxy=$http_proxy

apt="$(which apt) -V"
if $isDebianLike;then
	# CONFIG du Swap
	vgOS=$(findmnt / -n -o source | awk -F '[/-]' '{print$4}')
	grep /dev/$vgOS/swap /etc/fstab -q || echo -e "/dev/$vgOS/swap\tnone\tswap\tsw\t0\t0" | sudo tee -a /etc/fstab # Ajout du "swap" dans le /etc/fstab

	$sudo sysctl -w kernel.dmesg_restrict = 0 # Allows users to run "dmesg"
	echo kernel.dmesg_restrict = 0 | sudo tee -a /etc/sysctl.d/99-$companyNAME.conf
	$sudo systemctl restart systemd-sysctl.service

	hostnamectl status | grep 'Chassis: laptop'

	# CONFIG UFW
	$sudo sed -i "s/IPV6.*/IPV6=no/" /etc/default/ufw
	$sudo ufw reload
#	$sudo ufw allow OpenSSH || $sudo ufw allow ssh
#	$sudo ufw allow cups
	localNetwork=$(ip -4 route show dev $(ip -4 route show default | awk '{printf$5;exit}') | awk '!/default/&&!/169.254.0.0\/16/{printf$1;exit}')
	$sudo ufw allow from $localNetwork to any app OpenSSH
	$sudo ufw allow from $bastion to any app OpenSSH
	$sudo ufw allow 1022/tcp comment "do-release-upgrade alternate SSH port"
	$sudo ufw allow from $ourIP to any port 1022 proto tcp comment "do-release-upgrade alternate SSH port"

#	sudo ufw allow "Nginx HTTPS"

	grep "preserve_hostname:\s*true" /etc/cloud/cloud.cfg -q && sudo sed -i "s/preserve_hostname: true/preserve_hostname: false/" /etc/cloud/cloud.cfg
	sudo touch /etc/cloud/cloud-init.disabled # To Disable Cloud-Init

	# CONFIG KEYBOARD LAYOUT
	localectl set-x11-keymap fr pc105 latin9
	sudo localectl set-keymap fr # Ne marche plus depuis Ubuntu 22.04
	sudo localectl set-locale LANG=en_US.UTF-8

	hostnamectl status

	if < /dev/tcp/$proxyIP/http;then
		# CONFIG PROXY
  		egrep http_proxy= $HOME/.profile -q  || echo -e "\nexport http_proxy=$http_proxy"   >> $HOME/.profile
  		egrep https_proxy= $HOME/.profile -q || echo -e "\nexport https_proxy=$https_proxy" >> $HOME/.profile
  		sudo grep '^[^#]\s*.*env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"' | sudo tee -a /etc/sudoers.d/proxy
    
		# man apt-transport-http apt-transport-https
#		grep ^Acquire.*$http_proxy /etc/apt/apt.conf.d/*proxy -q || $sudo cat <<-EOF | sudo tee /etc/apt/apt.conf.d/00aptproxy
#			Acquire::http::proxy "$http_proxy";
#			Acquire::https::proxy "$https_proxy";
#EOF

		$sudo $apt update
		$sudo $apt upgrade -y $aptSimul

		# CONFIG SNAPD
		sudo snap set system proxy.http=$http_proxy
		sudo snap set system proxy.https=$https_proxy
		sudo snap get system proxy
		snap debug connectivity

		# CONFIG GIT
		git config --global http.proxy  $http_proxy
		git config --global https.proxy $https_proxy
  		git config --global -l | egrep https?.proxy

		# CONFIG DNS
		resolvectl status $iface
		DNS_SERVER1=X.Y.Z.T1
		FallBack_DNS_SERVER=X.Y.Z.T2
		DOMAIN=my.domain
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
			$sudo rm -fv /var/lib/ubuntu-release-upgrader/release-upgrade-available
			$sudo /usr/lib/ubuntu-release-upgrader/release-upgrade-motd
			timeout 5s /usr/lib/ubuntu-release-upgrader/check-new-release;echo $? # FLUX http-proxy a ouvrir vers X.Y.Z.T4
		fi

		$sudo $apt install ca-certificates
		sudo update-ca-certificates --fresh
		ll /etc/ssl/certs/ | grep Gandi

		$sudo $apt install net-tools -y $aptSimul # Pour netstat
		$sudo $apt install ugrep btop plocate gh fd-find # UBUNTU >= 22.04
		$sudo $apt install landscape-common # cf. https://github.com/canonical/landscape-client/blob/master/debian/landscape-common.install
		$sudo $apt  install ca-certificates debsecan ncdu ripgrep silversearcher-ag ack progress gcp shellcheck command-not-found nmon smartmontools iotop lsof net-tools pwgen ethtool smem sysstat fzf grep gawk sed curl remake wget jq jid vim dfc lshw screenfetch bc units lsscsi jq btop htop apt-file dlocate pv screen rsync x11-apps mc landscape-common parted gdisk ipcalc -y

		# $sudo $apt install -t $(lsb_release -sc)-backports smartmontools # On debian 10
		egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q || $sudo update-smart-drivedb -u github

		# CONFIG SYSSTAT
		if dpkg -l | grep sysstat -q;then
			debconf-show sysstat 2>/dev/null | grep sysstat/enable
			# $sudo debconf-set-selections <<< "sysstat sysstat/enable boolean true" # get overwritten by the ENABLED parameter in /etc/default/sysstat
			$sudo sed -i 's/^ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
			$sudo dpkg-reconfigure sysstat -f noninteractive # pour le bon fonctionnement de l'outil "sar"
			debconf-show sysstat 2>/dev/null | grep sysstat/enable
		fi

		$sudo $apt install gpm
		dpkg -s gpm | grep installed -q && systemctl -at service | grep gpm -q && sudo systemctl stop gpm && sudo systemctl disable gpm
		$sudo $apt install glances -y && dpkg -s glances | grep installed -q && systemctl -at service | grep glances -q && sudo systemctl stop glances && sudo systemctl disable glances

		if systemctl list-unit-files | grep cloud.*enabled.*enabled -q;then
			systemctl list-unit-files | awk '/cloud-init\..*enabled.*enabled/{print$1}' | while read service;do
				$sudo systemctl stop $service
				$sudo systemctl disable $service
				$sudo systemctl mask $service
			done
		fi

		# CONFIG GRUB
#		grep GRUB_TIMEOUT_STYLE=hidden /etc/default/grub -q && $sudo sed -i.orig "s/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/;s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=15/" /etc/default/grub
		grep GRUB_TIMEOUT_STYLE=hidden /etc/default/grub /etc/default/grub.d/* -q && echo -e "GRUB_TIMEOUT_STYLE=menu\nGRUB_TIMEOUT=15" | sudo tee -a /etc/default/grub.d/myCompany-grub.cfg
#  		grep '\#GRUB_GFX_MODE=' /etc/default/grub -q && $sudo sed -i.orig.2 "s/#GRUB_GFX_MODE=.*/GRUB_GFX_MODE=1152x864/" /etc/default/grub
		grep '\#GRUB_GFX_MODE=' /etc/default/grub /etc/default/grub.d/* -q && echo "GRUB_GFX_MODE=1152x864" | sudo tee -a /etc/default/grub.d/myCompany-grub.cfg
		$sudo update-grub

		# CONFIG SNMP
		$sudo $apt install snmp snmpd -y $aptSimul 
		$sudo $apt install snmp-mibs-downloader -y $aptSimul # Necessaire depuis Ubuntu 12.04 cf. https://thejoyofstick.com/blog/2019/05/28/installing-snmp-mib-files-in-linux-ubuntu-12-04-lts/

		ss -4nul | grep :161
		$sudo systemctl stop snmpd
		if which net-snmp-create-v3-user >/dev/null 2>&1;then
			grep rouser.svc_snmp /usr/share/snmp/snmpd.conf -q    || sudo net-snmp-create-v3-user -ro -X AES -A MD5 svc_snmp # Les MDPs sont a saisir de maniere interactive
			grep rouser.svc_snmp_v3 /usr/share/snmp/snmpd.conf -q || sudo net-snmp-create-v3-user -ro -X AES -A SHA-512 svc_snmp_v3 # Les MDPs sont a saisir de maniere interactive
		else
			$sudo $apt libsnmp-dev -y $aptSimul # Pour "net-snmp-config"
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
			$sudo grep includeAllDisks /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.d/$companyNAME-snmpd.conf -q  2>/dev/null || echo includeAllDisks 20% | sudo tee -a /etc/snmp/snmpd.conf.d/$companyNAME-snmpd.conf
			egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor -q && sudo sed -i.BACKUP "/^sysLocation.*/s/^sysLocation.*/sysLocation    Hosted on our VMware ESX Cluster/" /etc/snmp/snmpd.conf
			$sudo systemctl start snmpd
		fi
		ss -4nul | grep :161

		$sudo ufw allow snmp
		$sudo ufw status numbered

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

		# CONFIG TIMEZONE
		timedatectl status | grep Time.zone:.Europe/Paris -q || { $sudo timedatectl set-timezone Europe/Paris; sudo dpkg-reconfigure tzdata; }

		$sudo $apt install systemd-timesyncd

		sudo mkdir -p /etc/systemd/timesyncd.conf.d/
		echo [Time] | sudo tee /etc/systemd/timesyncd.conf.d/myConpany-timesyncd.conf

		grep "^NTP=$NTP_SERVER1" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "NTP=$NTP_SERVER1" | sudo tee -a /etc/systemd/timesyncd.conf.d/myConpany-timesyncd.conf
		grep "^FallbackNTP=$FALLBACK_NTP" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "FallbackNTP=$FALLBACK_NTP" | sudo tee -a /etc/systemd/timesyncd.conf.d/myConpany-timesyncd.conf
		grep "^RootDistanceMaxSec=$RootDistanceMaxSec" /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/* -q || echo "RootDistanceMaxSec=$RootDistanceMaxSec" | sudo tee -a /etc/systemd/timesyncd.conf.d/myConpany-timesyncd.conf

		$sudo systemctl restart systemd-timesyncd
		$sudo timedatectl set-ntp false; sudo timedatectl set-ntp true # Relance une synchro NTP
		timedatectl timesync-status
		timedatectl status
		timedatectl show

		egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q || $sudo hwclock --systohc

		# CONFIG SYSLOG
		syslogSERVER=X.Y.Z.T3
		grep $syslogSERVER /etc/rsyslog.conf /etc/rsyslog.d/* -q || echo "*.* @$syslogSERVER" | $sudo tee -a /etc/rsyslog.d/$companyNAME-rsyslog.conf
		$sudo systemctl restart rsyslog

		mkdir -p $HOME/.vim
		touch $HOME/.vim/vimrc
		$sudo mkdir -p /root/.vim
		$sudo touch /root/.vim/vimrc

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
			alias lastfiles="$find . -xdev -type f -mmin -2"
			alias lastfilestoday="$find . -type f -ctime -1"
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
