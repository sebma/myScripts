#!/usr/bin/env sh

set -o errexit
set -o nounset

LANG=C

if ! test -x $0 
then
  chmod u+x $0
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
fi
echo "=> distribName = $distribName"

if [ $distribName = gentoo ]
then
	pgrep -f gpm >/dev/null || gpm -m /dev/input/mouse0 -t ps2
#	emerge sudo
fi

if [ $distribName = ubuntu ]
then
  sed -i "/\/archive.ubuntu.com/s/archive.ubuntu.com/fr.archive.ubuntu.com/" /etc/apt/sources.list
  sed -i "/^deb cdrom/s/^/# /" /etc/apt/sources.list

  sudo add-apt-repository universe;sudo add-apt-repository multiverse

  add-apt-repository "deb http://security.ubuntu.com/ubuntu/ $(lsb_release -sc)-security universe multiverse"
  add-apt-repository "deb http://fr.archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-updates universe multiverse"
fi

toolList="dmidecode lspci lscpu lshw lspcmcia lsusb dmesg xrandr nm-tool fsarchiver"
#type $toolList | grep found && exit 1
for tool in $toolList
do
	type $tool >/dev/null 2>&1 || {
		rc=$?
		if [ $distribName = ubuntu ] 
		then
			if [ $tool = fsarchiver ] || [ $tool = hal ]
			then
				echo "=> WARNING: <$tool> is not installed." >&2
				apt-cache show $tool >/dev/null 2>&1 || {
					echo "=> Mise a jour de la liste des paquets presents dans les depots logiciels, cela dure environ 60 secondes ..."
					$(which time) -p apt-get update -qq
				}
			  echo "=> Installation du paquet <$tool> ..."
				apt-get install $tool -qq -V && rc=0
			else
				echo "=> ERROR: $tool is not installed." >&2
			fi
		else
			echo "=> ERROR: $tool is not installed." >&2
		fi
	}
done

test $rc != 0 && exit

assetTag=$(dmidecode -s chassis-asset-tag | egrep -v "Not Specified|^(Asset.|ATN)1234567890" || true)
reportFile="`dmidecode -s system-manufacturer | sed 's/ Inc.\| INC.//'`__` dmidecode -s system-product-name`__`dmidecode -s baseboard-product-name`"
test "$assetTag" && reportFile=${reportFile}__$assetTag
reportFile="${reportFile}__`basename $0 .sh`_sh__$distribName"
reportFile="`echo $reportFile | sed 's/ \|(\|\./_/g;s/)//g'`.txt"
XorgFile=Xorg__$(echo $reportFile | sed 's/.txt/.log/')

#rm -vf "$reportFile"
echo "=> Terminal : $(tput cols)x$(tput lines)" | tee "$reportFile"
#test -f "$reportFile" || {
{
	set -o errexit
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
	echo "=> Hostname : "
	hostname
	type lsb_release >/dev/null 2>&1 && {
		echo "=> Linux Standard Base Release Information :"
		lsb_release -cdir
	}
	echo "=> Kernel release and architecture :"
	uname -ri
	echo "=> Ethernet IP Address :"
	ifconfig eth | awk '/inet/{print $2}'
	echo "=> Ethernet MAC Address :"
	ifconfig eth | awk '/ether/{print $2}'
	echo "=> Mainboard Name :"
	dmidecode -s baseboard-product-name
	type lshwal >/dev/null 2>&1 && hal-get-property --udi /org/freedesktop/Hal/devices/computer --key system.board.product
	echo "=> Bios information :"
	for keyword in bios-vendor bios-version bios-release-date; do printf "%s " $(dmidecode -s $keyword); done; echo
	echo "=> System information :"
	for keyword in system-manufacturer system-product-name system-version system-serial-number system-uuid; do printf "%s " $(dmidecode -s $keyword); done; echo
	echo "=> Basebord information :"
	for keyword in baseboard-manufacturer baseboard-product-name baseboard-version baseboard-serial-number baseboard-asset-tag; do printf "%s " $(dmidecode -s $keyword); done; echo
	echo "=> Chassis information :"
	for keyword in chassis-manufacturer chassis-type chassis-version chassis-serial-number chassis-asset-tag; do printf "%s " $(dmidecode -s $keyword); done; echo
	echo "=> Processor information :"
	for keyword in processor-family processor-manufacturer processor-version processor-frequency; do printf "%s " $(dmidecode -s $keyword); done; echo
	echo "=> CPU Name :"
	grep name /proc/cpuinfo
	echo "=> Capacite memoire maximum estimee :"
	dmidecode -qt memory | grep "Maximum Capacity:"
	echo "=> Memory information :"
	dmidecode -qt memory | egrep $'\tLocator:|Size:|Factor:|Type:|Speed:'
	echo "=> Northbridge Chipset :"
	lspci -nnvs 0:0.0 | egrep "00:00.0|Kernel|Subsystem"
	echo "=> Southbridge Chipset :"
	lspci | awk '/ISA bridge/{print$1}' | xargs -i lspci -nnvs "{}" | egrep "ISA bridge|Kernel"
	echo "=> Video Controler :"
	lspci | awk '/Display|VGA/{print$1}' | xargs -i lspci -vvvvnns "{}" | egrep -w "Display|VGA|Kernel"
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
	}
	echo "=> Chassis Asset Tag = $assetTag"
	printf "=> Resolution ecran courrante : "
	xrandr | awk -F" *|\+" '/ connected/{print $3}'
	echo "=> Resolutions ecrans possibles :"
	xrandr
	test -x /usr/lib/nux/unity_support_test && {
		echo "=> Unity 3D ?"
		/usr/lib/nux/unity_support_test -p || true
	}
	echo "=> Disk partionning scheme :"
#	set -x
	for diskDevice in `ls /dev/sd?` ; do test -b $diskDevice && parted $diskDevice print; done || parted -l
	df -Th | grep ^/dev/sd | sort
	echo "=> /proc/scsi/scsi :"
	cat /proc/scsi/scsi
	echo "=> Disk information :"
	lshw -numeric -sanitize -businfo -c disk
	echo
	fsarchiver -V
	echo
	fsarchiver probe detailed 2>&1 | sed "/dev\|UUID/s/....$/]/"
	echo
	blkid
	echo
	test -r /sys/block/sda/device/../../../vendor && {
		echo "=> Informations sur le controler SATA/PATA via sysfs et lspci :"
		lspci -nnd $(cat /sys/block/sda/device/../../../vendor):$(cat /sys/block/sda/device/../../../device)
	}
	echo "=> Hard Disk Drive Information :"
	hdparm -i /dev/sda
	echo
	hdparm -I /dev/sda | grep speed || true
	hdparm -I /dev/sda
	cat /proc/ide/ide?/model || true
	dmesg | grep -i ata[0-9]
	cat /proc/scsi/scsi | sed '/scsi0/,/Type/!d'
	echo
	echo "=> Framebuffer support :"
	ls -l /dev/fb* || true
	echo
	lshw -numeric -sanitize -businfo
	echo "=> CPU Information :"
	#lscpu
	echo "=> /proc/cpuinfo :"
	cat /proc/cpuinfo
	echo "Memory slots info :"
	dmidecode -qt 17 
	type update-pciids >/dev/null 2>&1 && update-pciids
	echo "=> Liste des pilotes utilises :"
	lspci -nnv | egrep "^[0-9a-f]|Kernel"
	echo "=> Network controllers:"
	lspci | awk '/Network|Ethernet/{print$1}' | xargs -i lspci -nnvs "{}" | egrep "Network|Ethernet|Kernel"
	lshw -numeric -sanitize -businfo -c network
	echo "=> Network interfaces:"
	ip addr show | awk '{print $2}' | sed "/[^:]$/s/^/\t/"
	iwconfig 2>/dev/null
	echo "=> Available Wifi Networks :"
	nm-tool
	echo "=> South card information :"
	cat /proc/asound/pcm || true
	grep -w name /proc/asound/card?/pcm?p/info || true
	echo "=> Is compiz running ?"
	pgrep -lf compiz && echo "=> Yes, compiz is running." || {
		echo "=> Nope, compiz cannot run here with $(lsb_release -sd)."
		rsync -Pt /var/log/Xorg.0.log $XorgFile
	}
	type update-usbids >/dev/null 2>&1 && update-usbids -q
	echo "=> Informations USB :"
	lsusb
	usb-devices | egrep "^T: |Manufacturer|Product"
	echo "=> Informations PCMCIA :"
	lspcmcia
	echo "=> Driver utilise pour la video :"
	lspci | awk '/VGA/{print$1}' | xargs -i lspci -vs "{}" | grep Kernel
	echo "=> Quantite de memoire presente sur la carte video :"
	lspci | awk '/VGA/{print$1}' | xargs -i lspci -vs "{}" | awk '/Memory.*size=[0-9]+[M|G]/{print$NF}'
	echo "=> Infos cartes Son et cartes Graphiques :"
	lshw -C multimedia -C display -numeric -sanitize 
	lspci | awk '/Audio|Display|VGA/{print$1}' | xargs -i lspci -vvnns "{}"
	echo "=> Informations generales via <dmidecode> ..."
	dmidecode -q
	echo "=> Informations generales via <lshw> ..."
	lshw -numeric -sanitize

	socket=$(dmidecode -t processor | awk -F": " '/Upgrade: Socket|Socket Designation:/{print$2}' | egrep -wv "CPU" || true)
	test "$socket" || socket=$(lshw -c processor | awk -F": " '/slot/{print$2}' | egrep -wv "CPU" || true)
	echo
	echo "=> Socket CPU = $socket"
	echo

	echo "=> Les peripheriques non reconnus: "
	lshw | egrep -A3 "UNCLAIMED"
	echo

	keywordList="bios-vendor bios-version bios-release-date system-manufacturer system-product-name system-version system-serial-number system-uuid baseboard-manufacturer baseboard-product-name baseboard-version baseboard-serial-number baseboard-asset-tag chassis-manufacturer chassis-type chassis-version chassis-serial-number chassis-asset-tag processor-family processor-manufacturer processor-version processor-frequency"
	for keyword in $keywordList ; do value=`dmidecode -s $keyword`; test "$value" && printf "=> %23s : %40s\n" $keyword "$value" ; done
	echo
	echo "=> The report file $reportFile"
} 2>&1 | tee -a "$reportFile"

echo
pgrep -lf compiz >/dev/null || echo "=> XorgFile = $XorgFile"
