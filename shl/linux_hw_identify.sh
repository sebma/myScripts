#!/usr/bin/env bash

#set -o errexit
set -o nounset

LANG=C

if ! test -x $0 
then
  chmod u+x $0 || sudo chmod u+x $0
fi

rc=0

isLinux=$(uname -s | grep -q Linux && echo true || echo false)
distribName=""
if $($isLinux)
then
	distribName=$(\ls -1 /etc/*release /etc/*version 2>/dev/null | awk -F"/|-|_" '!/system/ && NR==1 {print$3}')
	test $distribName = debian && distribName=$(awk -F= '/DISTRIB_ID/{print tolower($2)}' /etc/lsb-release)
else
	distribName=Unix
	echo "=> ERROR: This script cannot run on $distribName."
	exit 1
fi
echo "=> distribName = $distribName"

isAdmin=$(sudo -v && echo true || echo false)
if $isAdmin
then
	echo "=> Elevation de privileges reussie."
	sudo_cmd=sudo
else
	echo "=> Echec d'elevation de privileges." >&2
	echo "=> Ce script tournera en tant que l'utilisateur <$USER> uniquement." >&2
	sudo_cmd=""
fi
echo


configureSudoersForGroup() {
	echo "=> Configuring <sudoers> for $distribName ..."
	groupName=$1
	su -c "grep -q admin /etc/sudoers" || {
		echo "=> Creating the $groupName group in the <sudoers> file for $distribName ..."
		su -c "printf \"%%$groupName\tALL=(ALL)\tALL\n\" >> /etc/sudoers"
	}
	grep -q $groupName /etc/group || {
		echo "=> Creating the <$groupName> group for $distribName ..."
		su -c "groupadd $groupName"
	}
	id -Gn | grep -q $groupName || {
		echo "=> Adding <$USER> in the <$groupName> group ..."
		su -c "usermod -G $groupName $USER"
		echo "=> Please logoff and logon again."
		exit
	}
}

function init() {
if $isAdmin
then
	case $distribName in
		ubuntu|debian)
			toolList="dmidecode edid-decode lspci lscpu lshw lspcmcia lsusb dmesg xrandr nm-tool fsarchiver lshal hwinfo usb-devices"
			whatPackageContains() {
				/usr/lib/command-not-found $1 2>&1 | awk '/apt-get/{print$NF}'
			}
			installPackages="sudo apt install -qq -V"
			cleanPackages="sudo apt-get clean"
			if [ $distribName = ubuntu ]
			then
			  sudo sed -i "/\/archive.ubuntu.com/s/archive.ubuntu.com/fr.archive.ubuntu.com/" /etc/apt/sources.list
			  sudo sed -i "/^deb cdrom/s/^/# /" /etc/apt/sources.list
			
#			sudo add-apt-repository "http://fr.archive.ubuntu.com/ubuntu/ universe multiverse"
			
	#		  sudo add-apt-repository "deb http://security.ubuntu.com/ubuntu/ $(lsb_release -sc)-security universe multiverse"
	#		  sudo add-apt-repository "deb http://fr.archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-updates universe multiverse"
			fi
			;;
		gentoo)
			toolList="dmidecode edid-decode lspci lscpu lshw lspcmcia lsusb dmesg xrandr nm-tool fsarchiver"
			installPackages="sudo emerge"
			pgrep -f gpm >/dev/null || gpm -m /dev/input/mouse0 -t ps2
			installPackages="emerge"
			$installPackages sudo
			;;
		redhat|centos)
			echo $PATH | grep -qw sbin || {
			test -f $HOME/.profile && echo 'export PATH=$PATH:/sbin:/usr/sbin' >> $HOME/.profile || echo 'export PATH=$PATH:/sbin:/usr/sbin' >>$HOME/.bash_profile
				echo "=> Please logoff and logon again."
				exit
			}
			id -Gn | grep -q admin || configureSudoersForGroup admin
			toolList="dmidecode edid-decode lspci lshw lspcmcia lsusb dmesg xrandr nm-tool"
			whatPackageContains() {
				yum -q provides "*bin/$1" | sed -n "s/^[0-9][^:]*:\|-[0-9].*//g;1p"
			}
			installPackages="sudo yum install"
			cleanPackages="sudo yum clean packages"
			;;
		*) ;;
	esac
fi
}

init

function installRequiredPackages() {
if $isAdmin
then
	#type $toolList | grep found && exit 1
	for tool
	do
#		[ $tool = usb-devices ] && set -x
		echo "=> tool = $tool" >&2
#		type $tool >/dev/null 2>&1 || {
		if type $tool >/dev/null 2>&1 ; then
				rc=$?
				if [ $distribName = ubuntu ] ||  [ $distribName = redhat ]
				then
		#			if [ $tool = fsarchiver ] || [ $tool = hal ] || [ $tool = hwinfo ]
		#			then
						echo "=> WARNING: <$tool> is not installed." >&2
						pkgName=$(whatPackageContains $tool)
						echo "=> pkgName = $pkgName"
						test $pkgName || {
							echo "=> WARNING: The package for <$tool> could not be found, skiping ..."
							continue
						}
		#				pkgName=$(/usr/lib/command-not-found $tool 2>&1 | awk '/apt-get/{print$NF}')
						if [ $distribName = ubuntu ]
						then
							 apt-cache -q show $pkgName >/dev/null 2>&1 || {
								echo "=> Mise a jour de la liste des paquets presents dans les depots logiciels, cela dure environ 60 secondes ..."
								$(which time) -p sudo apt-get update -qq
							}
						fi
						echo "=> Installation du paquet <$pkgName> ..."
						$installPackages $pkgName && rc=0
						$cleanPackages
		#			else
		#				echo "=> ERROR: $tool is not installed." >&2
		#			fi
				else
					echo "=> ERROR: $tool is not installed." >&2
				fi
#		}
		fi
	done
fi
}

installRequiredPackages $toolList

test $rc != 0 && exit

assetTag=$($sudo_cmd dmidecode -s chassis-asset-tag | egrep -v "Not Specified|^(Asset.|ATN)1234567890")
test "$assetTag" || assetTag=unknown-chassis-asset-tag
reportFile="`$sudo_cmd dmidecode -s system-manufacturer | sed 's/ Inc.\| INC.//'`__` $sudo_cmd dmidecode -s system-product-name`__`$sudo_cmd dmidecode -s baseboard-product-name`"

test "$assetTag" && reportFile=${reportFile}__$assetTag
type lsb_release >/dev/null 2>&1 && reportFile="${reportFile}__`basename $0 .sh`_sh__`lsb_release -sd`" || reportFile="${reportFile}__`basename $0 .sh`_sh__$distribName"

logDir=~/log
mkdir $logDir
reportFile="$logDir/`echo $reportFile | sed 's/ \|(\|\./_/g;s/)//g'`.txt"
XorgFile=$logDir/Xorg__$(echo $reportFile | sed 's/.txt/.log/')

echo "=> Terminal : $(tput cols)x$(tput lines)" | $sudo_cmd tee "$reportFile"
#test -f "$reportFile" || {
{
#	set -o errexit
	set -o nounset

	echo "=> Using the following tools versions :"
#	set -x
	dmidecode -V
	lspci --version
	lshw -version
	lspcmcia -V
	lsusb -V
	xrandr --version
#	set +x
	echo "=> OK, now lets begin the analysis ..."
	echo "=> System summary :"
	inxi -c0 -Ad -v3
	echo "=> A lot more inxi information :) :"
	inxi -c0 -fwv7
	echo "=> Repositories list"
	inxi -r
#	lspci -mmnnv
	echo "=> Hostname : "
	hostname
	echo "=> Type de clavier :"
	setxkbmap -print | awk -F'"' '/geometry/{print$2}'
	type lsb_release >/dev/null 2>&1 && {
		echo "=> Linux Standard Base Release Information :"
		lsb_release -cdir
	}
	echo "=> Kernel release and architecture :"
	uname -ri
	echo "=> Ethernet IP Address :"
	ifconfig eth | awk -F ":| *" '/inet addr/{print $4}'
	ip addr show dev eth0 | awk '/inet/{print$2}'
	echo "=> Ethernet MAC Address :"
	test -r /sys/class/net/eth0/address && cat /sys/class/net/eth0/address || ifconfig eth | awk '/HWaddr/{print $NF}'
	ip addr show dev eth0 | awk '/ether/{print$2}'
	echo "=> Wifi IP Address :"
	ifconfig wlan | awk -F ":| *" '/inet addr/{print $4}'
	ip addr show dev wlan0 | awk '/inet/{print$2}'
	echo "=> Wifi MAC Address :"
	test -r /sys/class/net/wlan0/address && cat /sys/class/net/wlan0/address || ifconfig eth | awk '/HWaddr/{print $NF}'
	ip addr show dev wlan0 | awk '/ether/{print$2}'
	echo "=> WAN IP Address :"
#	curl -s http://smxi.org/opt/ip.php | awk '/address/{print$NF}'
#	curl -s tnx.nl/ip; echo
#	wget -qO- ip.appspot.com; echo
	dig +short myip.opendns.com @resolver1.opendns.com
	echo "=> Mainboard Name :"
	$sudo_cmd dmidecode -s baseboard-product-name
	type lshal >/dev/null 2>&1 && hal-get-property --udi /org/freedesktop/Hal/devices/computer --key system.board.product
	echo "=> Bios information :"
	for keyword in bios-vendor bios-version bios-release-date; do printf "%s " $($sudo_cmd dmidecode -s $keyword); done; echo
	echo "=> System information :"
	for keyword in system-manufacturer system-product-name system-version system-serial-number system-uuid; do printf "%s " $($sudo_cmd dmidecode -s $keyword); done; echo
	echo "=> Basebord information :"
	for keyword in baseboard-manufacturer baseboard-product-name baseboard-version baseboard-serial-number baseboard-asset-tag; do printf "%s " $($sudo_cmd dmidecode -s $keyword); done; echo
	echo "=> Chassis information :"
	for keyword in chassis-manufacturer chassis-type chassis-version chassis-serial-number chassis-asset-tag; do printf "%s " $($sudo_cmd dmidecode -s $keyword); done; echo
	echo "=> Processor information :"
	for keyword in processor-family processor-manufacturer processor-version processor-frequency; do printf "%s " $($sudo_cmd dmidecode -s $keyword); done; echo
	echo "=> CPU Name :"
	grep name /proc/cpuinfo | uniq -c
	egrep -q "vmx|svm" /proc/cpuinfo && echo "=> CPU supports hardware virtualisation."
	echo "=> Capacite memoire maximum estimee :"
	$sudo_cmd dmidecode -qt memory | grep "Maximum Capacity:"
	echo "=> Memory information from /proc/meminfo :"
	awk --re-interval '/[0-9]{4}| 0 /{sub($(NF-1)" kB",$(NF-1)/2^10" mB")}/[0-9]{4}| 0 /{sub($(NF-1)" mB",$(NF-1)/2^10" gB")}{print}' /proc/meminfo|column -t
	echo "=> Memory information with dmidecode :"
	$sudo_cmd dmidecode -qt memory | egrep $'\tLocator:|Size:|Factor:|Type:|Speed:'
	echo "=> Northbridge Chipset :"
	lspci -nnvs 0:0.0 | egrep "00:00.0|Kernel|Subsystem"
	echo "=> Southbridge Chipset :"
	lspci | awk '/ISA bridge/{print "lspci -nnvs " $1}' | sh
	echo "=> Video Controler :"
	lspci | awk '/Display|VGA/{print "lspci -vnns " $1}' | $sudo_cmd sh | egrep -w "Display|VGA|Kernel"
	echo "=> Video Chipset :"
	egrep -h "PCI:|Chipset:|intel: Driver" /var/log/Xorg.0.log
	dmesg | grep agp
	echo "=> Keyboard information ..."
	setxkbmap -print | awk -F'"' '/geometry/{print$2}'
	echo "=> Network information :"
	ip addr show | awk '{print $2}' | sed "/[^:]$/s/^/\t/"
	ls /dev/sr? >/dev/null 2>&1 && {
		mountedCDRDevice=$(mount | awk '/on \/media\/.* type iso9660/{print $1}')
		test $mountedCDRDevice && umount -vv $mountedCDRDevice
		echo "=> CDROM Drive capabilities :"
		CDR_DEVICE=/dev/sr0 cdrecord -prcap
		echo "=> CDROM Drive capabilities from /proc :"
		cat /proc/sys/dev/cdrom/info
	}
	echo "=> Chassis Asset Tag = $assetTag"
	echo "=> Informations sur le moniteur :"
#	$sudo_cmd ddcprobe
	driverName=$(lspci | awk  '/VGA/{print "lspci -vs " $1}' | sh | awk '/driver/{print$NF}')
	grep -i ".--.*$driverName([0-9])" /var/log/Xorg.0.log
	find /sys -name edid 2>/dev/null | awk 'END{print "edid-decode " $0}' | sh
	printf "=> Resolution ecran courrante : "
	xrandr | awk -F" *|\+" '/ connected/{print $3}'
	echo "=> Resolutions ecrans possibles :"
	xrandr
	test -x /usr/lib/nux/unity_support_test && {
		echo "=> Unity 3D ?"
		/usr/lib/nux/unity_support_test -p
	}
	echo "=> Disk partionning scheme :"
#	set -x
	for diskDevice in `ls /dev/sd?` ; do test -b $diskDevice && echo c | $sudo_cmd parted $diskDevice print; done || $sudo_cmd parted -l
	df -Th | grep ^/dev/sd | sort
	echo "=> /proc/scsi/scsi :"
	cat /proc/scsi/scsi
	echo "=> Disk information :"
	test $distribName = redhat && $sudo_cmd lshw -sanitize -businfo -C disk || $sudo_cmd lshw -numeric -sanitize -businfo -C disk
	echo
	type fsarchiver >/dev/null 2>&1 && {
		fsarchiver -V
		echo
		$sudo_cmd fsarchiver probe detailed 2>&1 | sed "/dev\|UUID/s/....$/]/"
		echo
	}
	echo "=> Block Device Attributes Information ..."
	blkid
	echo
	test -r /sys/block/sda/device/../../../vendor && {
		echo "=> Informations sur le controler SATA/PATA via sysfs et lspci :"
		lspci -nnd $(cat /sys/block/sda/device/../../../vendor):$(cat /sys/block/sda/device/../../../device)
	}
	echo "=> Hard Disk Drive Information :"
	$sudo_cmd hdparm -i /dev/sda
	echo
	$sudo_cmd hdparm -I /dev/sda | grep speed
	$sudo_cmd hdparm -I /dev/sda
	cat /proc/ide/ide?/model
	dmesg | grep -i ata[0-9]
	cat /proc/scsi/scsi | sed '/scsi0/,/Type/!d'
	echo
	echo "=> Framebuffer support :"
	ls -l /dev/fb*
	type hwinfo >/dev/null 2>&1 && {
		$sudo_cmd hwinfo --framebuffer
		echo "=> Resume de detection materielle par <hwinfo> ..."
		$sudo_cmd hwinfo --short
	}
	echo "=> Resume de detection materielle par <lshw> ..."
	test $distribName = redhat && $sudo_cmd lshw -sanitize -businfo || $sudo_cmd lshw -numeric -sanitize -businfo
	echo "=> CPU Information :"
	lscpu
	echo "=> /proc/cpuinfo :"
	egrep "Hz|name|cpu cores" /proc/cpuinfo | sort | uniq -c
	echo "Memory slots info :"
	$sudo_cmd dmidecode -qt 17
	type update-pciids >/dev/null 2>&1 && $sudo_cmd update-pciids
	echo "=> Liste des pilotes utilises :"
	lspci -nnv | egrep "^[0-9a-f]|Kernel"
	echo "=> Network devices:"
	lspci | awk '/Network|Ethernet/{print "lspci -nnvs " $1}' | sh | egrep "Network|Ethernet|Kernel"
	test $distribName = redhat && lshw -sanitize -businfo -C network || lshw -numeric -sanitize -businfo -C network
	echo "=> Network software interfaces:"
	ip addr show | awk '{print $2}' | sed "/[^:]$/s/^/\t/"
	echo "=> Wireless software interfaces:"
	iwconfig 2>/dev/null
	echo "=> Wireless devices and their capacities:"
	iw list
	echo "=> Available Wifi Networks :"
	nm-tool
	echo "=> South card information :"
	cat /proc/asound/pcm
	grep -w name /proc/asound/card?/pcm?p/info
	echo "=> Is compiz running ?"
	pgrep -lf compiz && echo "=> Yes, compiz is running." || {
		echo "=> Nope, compiz cannot run here with $(lsb_release -sd)."
		$sudo_cmd rsync -Pt /var/log/Xorg.0.log $XorgFile
	}
	type update-usbids >/dev/null 2>&1 && $sudo_cmd update-usbids -q
	echo "=> Informations USB :"
	lsusb
	type usb-devices >/dev/null 2>&1 && usb-devices | egrep "^T: |Manufacturer|Product"
	echo "=> Informations PCMCIA :"
	lspcmcia
	echo "=> Driver utilise pour la video :"
	lspci | awk '/VGA/{printf "lspci -vs %s | grep Kernel\n", $1}' | sh
	echo "=> Quantite de memoire presente sur la carte video :"
	lspci | awk '/VGA/{print "lspci -vs " $1}' | sh | awk '/Memory.*size=[0-9]+[M|G]/{print$NF}'
	echo "=> Infos cartes Son et cartes Graphiques via <lspci> :"
	lspci | awk '/Audio|Display|VGA/{print "lspci -vnns " $1}' | sh
	echo "=> Infos cartes Son et cartes Graphiques via <lshw> :"
	test $distribName = redhat && $sudo_cmd lshw -C multimedia -C display -sanitize || $sudo_cmd lshw -C multimedia -C display -numeric -sanitize 
	echo "=> Informations generales via <dmidecode> ..."
	$sudo_cmd dmidecode -q
	echo "=> Informations generales via <lshw> ..."
	test $distribName = redhat && $sudo_cmd lshw -sanitize || $sudo_cmd lshw -numeric -sanitize

	socket=$($sudo_cmd dmidecode -t processor | awk -F": " '/Upgrade: Socket|Socket Designation:/{print$2}' | egrep -wv "CPU")
	test "$socket" || socket=$($sudo_cmd lshw -C processor | awk -F": " '/slot/{print$2}' | egrep -wv "CPU")
	echo
	echo "=> Socket CPU = $socket"
	echo

	echo "=> Les peripheriques non reconnus: "
	$sudo_cmd lshw | egrep -A3 "UNCLAIMED"
	echo

	keywordList="bios-vendor bios-version bios-release-date system-manufacturer system-product-name system-version system-serial-number system-uuid baseboard-manufacturer baseboard-product-name baseboard-version baseboard-serial-number baseboard-asset-tag chassis-manufacturer chassis-type chassis-version chassis-serial-number chassis-asset-tag processor-family processor-manufacturer processor-version processor-frequency"
	for keyword in $keywordList ; do value=`$sudo_cmd dmidecode -s $keyword`; test "$value" && printf "=> %23s : %40s\n" $keyword "$value" ; done
	echo
	echo "=> The report file is <$reportFile>."
} 2> "$reportFile".err | $sudo_cmd tee -a "$reportFile"

echo "=> The report file is <$reportFile>."
echo
pgrep -lf compiz >/dev/null || echo "=> XorgFile = $XorgFile"
