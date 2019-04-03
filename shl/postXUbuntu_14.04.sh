#!/usr/bin/env bash

set -o errexit
set -o nounset

LANG=C

AddRepositoriesNew() {
	repositoryList=$@
	printf "sudo add-apt-repository -y %s\n" $repositoryList | sh
	echo "=> Mise a jour de la liste des paquets presents dans les depots logiciels, cela dure environ 60 secondes ..."
	$(which time) -p sudo apt update -qq || true
}

AddRepositories() {
	distribCodeName=$(lsb_release -sc)
	distribRelease=$(lsb_release -sr)
	distribVersion=$(echo $distribRelease | cut -d. -f1)

	echo "=> Ajout des depots universe, multiverse et depots PPA puis mise a jour de la liste des paquets ..."
	echo
	echo "==> Desactivation de la source de type CD/DVD-ROM ..."
	sudo sed -i "/^deb cdrom/s/^/# /" /etc/apt/sources.list
	echo "==> Choix des mirroirs Francais pour la proximite ..."
	sudo sed -i "/\/archive.ubuntu.com/s/archive.ubuntu.com/fr.archive.ubuntu.com/" /etc/apt/sources.list

	if [ $distribRelease = 10.04 ]
	then
		sudo add-apt-repository "deb http://fr.archive.ubuntu.com/ubuntu/  $distribCodeName universe multiverse"
	else
		sudo add-apt-repository "http://fr.archive.ubuntu.com/ubuntu/ universe multiverse"
	fi

	sudo add-apt-repository "deb http://security.ubuntu.com/ubuntu/ $distribCodeName-security universe multiverse"
	sudo add-apt-repository "deb http://fr.archive.ubuntu.com/ubuntu/  $distribCodeName-updates universe multiverse"

	echo "==> Ajout du depot Ubuntu Partner :"
	if [ $distribRelease = 10.04 ]
	then
		sudo add-apt-repository "deb http://archive.canonical.com/ $distribCodeName partner"
	else
		sudo add-apt-repository "http://archive.canonical.com/ubuntu/ partner"
	fi

	echo "==> Suppression des depots sources ..."
	sudo sed -i "/deb-src/d" /etc/apt/sources.list

	echo "==> Ajout des depots Launchpad PPA ..."
	for ppa
	do {
		ppaRepository=$(echo $ppa | cut -d: -f2-)
		ppaFileName="$(echo $ppaRepository | tr / -)-$distribCodeName.list"
		ppaShortName="$(echo $ppaRepository | cut -d/ -f2- | tr [:lower:] [:upper:])" 
		case $ppaShortName in
			PPA|STABLE|STABLE-DAILY) ppaShortName="$(echo $ppaRepository | cut -d/ -f1 | tr [:lower:] [:upper:])"
			;;
			*) ;;
		esac

		if grep -q http://ppa.launchpad.net/$ppaRepository /etc/apt/sources.list.d/$ppaFileName 2>/dev/null
		then
			echo "==> Le depot PPA $ppa est deja present."
		else
			echo "==> Ajout du PPA $ppa pour $ppaShortName ..."
			test $(echo $distribRelease | cut -d. -f1) -gt 10 && addAptRepositoryOptions=-y || addAptRepositoryOptions=""
			sudo add-apt-repository $addAptRepositoryOptions $ppa >/dev/null
			grep -q "#$ppaShortName$" /etc/apt/sources.list.d/$ppaFileName 2>/dev/null || sudo sed -i "/^deb /s/$/ #$ppaShortName/" /etc/apt/sources.list.d/$ppaFileName
		fi
		echo
	}
	done
	sudo sed -i "/deb-src/d" /etc/apt/sources.list.d/*.list

	if ! apt-cache show smplayer >/dev/null 2>&1 ; then {
		echo "=> Mise a jour de la liste des paquets presents dans les depots logiciels, cela dure environ 60 secondes ..."
		$(which time) -p sudo apt-get update -qq || true
	}
	fi
}

if ! test -x $0
then
  chmod u+x $0 || sudo chmod u+x $0
fi

interpreter=$(ps -o pid,comm | awk /$$/'{print $2}')
if [ $interpreter != bash ] ; then {
  echo "=> Mauvais interpreteur (interpreter = $interpreter), veuillez relancer le script $(basename $0) de la maniere suivante: ./$0" >&2
  return 127
}
fi

initScript() {
	mkdir -p ~/.gnupg
	isLinux=$(uname -s | grep -q Linux && echo true || echo false)
	distribName=""
	if $($isLinux)
	then {
		distribName=$(\ls -1 /etc/*release /etc/*version | awk -F"/|-|_" '!/system/ && NR==1 {print$3}')
		test $distribName = debian && {
			distribName=$(awk -F= '/_ID=/{print tolower($2)}' /etc/lsb-release)
			distribCodeName=$(awk -F= '/_CODENAME=/{print tolower($2)}' /etc/lsb-release)
			distribRelease=$(awk -F= '/_RELEASE=/{print tolower($2)}' /etc/lsb-release)
			distribVersion=$(echo $distribRelease | cut -d. -f1)
		}
		echo "=> distribName = $distribName"
		echo "=> distribCodeName = $distribCodeName"
		echo "=> distribRelease = $distribRelease"
	}
	else {
		distribName=Unix
		echo "=> This script only runs on Linux." >&2
		exit 1
	}
	fi

	case $distribName in
	ubuntu|debian)
		installPackages="sudo apt install -V"
		purgePackages="sudo apt purge -qq -y"
		cleanPackages="sudo apt-get clean"
		distribRelease=$(lsb_release -sr)
	;;
	*)
		echo "=> ERROR: This script must be run on Ubuntu Linux." >&2
		exit 1
	;;
	esac
}

initScript
test -w /tmp || sudo chmod 1777 /tmp
test -w /var/tmp || sudo chmod 1777 /var/tmp

setMimes() {
	#Ouvrir les fichiers documents avec LibreOffice
	which libreoffice >/dev/null 2>&1 && {
		documentFileTypes=".doc .docx .sxw .odt .xls .xlsx .sxc .ods .ppt .pps .pptx .ppsx .sxi .odp"
		documentMimeTypes="$(mimetype -b $documentFileTypes | sort -u | xargs)"
		xdg-mime default libreoffice-startcenter.desktop $documentMimeTypes
		echo "=> Les fichiers $documentFileTypes s'ouvriront desormais avec <libreoffice>."
	}

	#Ouvrir les fichiers Audio avec audacious
	which audacious >/dev/null 2>&1 && {
		audioFileTypes=".wav .wma .aac .ac3 .mp2 .mp3 .ogg .m4a .spx .opus"
		audioMimeTypes="$(mimetype -b $audioFileTypes | grep audio | sort -u | xargs) audio/x-vorbis+ogg"
		xdg-mime default audacious.desktop $audioMimeTypes
		echo "=> Les fichiers $audioFileTypes s'ouvriront desormais avec <audacious>."
	}

	#Ouvrir les fichiers Video avec SMPlayer
	which smplayer >/dev/null 2>&1 && {
		videoFileTypes=".asf .avi .wmv .mpg .mpeg .mp4 .divx .flv .mov .ogv .webm .vob .ts .3gp .mkv"
		videoMimeTypes=$(mimetype -b $videoFileTypes | grep video | sort -u | xargs)
		xdg-mime default smplayer.desktop $videoMimeTypes
		echo "=> Les fichiers $videoFileTypes s'ouvriront desormais avec <smplayer>."
	}

	#Association du protocole apt: avec l'application apturl
	xdg-mime default apturl.desktop x-scheme-handler/apt

	#Ouvrir les fichiers .deb avec gdebi-gtk
	which gdebi-gtk >/dev/null 2>&1 && xdg-mime default gdebi.desktop application/x-deb
}

sudo grep -q pwfeedback /etc/sudoers.d/sudoers_$(id -u) || echo -e "Defaults\tenv_reset,pwfeedback" | tee -a /etc/sudoers.d/sudoers_$(id -u)
sudo chmod 0440 /etc/sudoers.d/sudoers_$(id -u)

grep -q ^GRUB_HIDDEN_TIMEOUT=0 /etc/default/grub && sudo sed -i"_$(date +%Y%m%d_%H%M%S).bak" "s/^.*GRUB_HIDDEN_TIMEOUT=0.*$/#GRUB_HIDDEN_TIMEOUT=0/" /etc/default/grub
sleep 1
grep -q GRUB_CMDLINE_LINUX_DEFAULT=.*quiet /etc/default/grub && sudo sed -i"_$(date +%Y%m%d_%H%M%S).bak" 's/^.*GRUB_CMDLINE_LINUX_DEFAULT=.*quiet.*$/GRUB_CMDLINE_LINUX_DEFAULT="splash"/' /etc/default/grub
sudo update-grub

if env | grep -q DISPLAY; then {
	echo "=> Chargement du clavier francais pour la session graphique courante ..."
	setxkbmap fr
}
fi

echo "=> Chargement du clavier francais dans les terminaux virtuels ..."
sudo loadkeys fr-latin9 || true

grep -q "set ts" ~/.exrc 2>/dev/null || echo set ts=2 >> ~/.exrc
grep -q "set ai" ~/.exrc 2>/dev/null || echo set ai >> ~/.exrc

franceTimeZone=Europe/Paris
if ! grep -q $franceTimeZone /etc/timezone; then {
	echo "=> Configuration du Fuseau horaire <$franceTimeZone> ..."
	echo $franceTimeZone | sudo tee /etc/timezone
}
fi

if ! grep -q "TZ=." /etc/environment; then {
	echo TZ=$franceTimeZone | sudo tee -a /etc/environment
}
fi
#sudo dpkg-reconfigure tzdata

for group in audio video saned lp dialout
do
	groups | grep -qw $group || {
		echo "=> Ajout de <$USER> dans le groupe <$group> ..."
		sudo adduser $USER $group
	}
done

dpkg -l | grep -q "^ii  ntp " && echo "=> Suppression du packet <ntp> incompatible avec <ntpdate> ..." && sudo apt-get -qq -y purge ntp
echo "=> L'heure affichee est elle correcte, si oui appuyer sur <ENTREE> ?"
env | grep -qw TZ && LANG=fr_FR.UTF-8 date || TZ=$franceTimeZone LANG=fr_FR.UTF-8 date
read answer
if echo $answer | egrep -q "N|n"; then {
	echo "=> Syncronisation de l'horloge avec les serveurs de temps, cela dure environ 10 secondes ..."
	if ! $(which time) -p sudo ntpdate ntp.ubuntu.com pool.ntp.org; then {
		echo "==> Les serveurs NTP: ntp.ubuntu.com et pool.ntp.org ne sont pas accessibles d'ici, veuillez saisir l'heure locale sous la forme HH:MM"
		read time
		if ! echo $time | grep -q "^[0-9][0-9]:[0-9][0-9]$"; then {
		  echo "==> ERREUR: L'heure saisie est invalide" >&2
			exit 2
		}
		fi

		printf "=> The date is now: "
		TZ=$franceTimeZone LANG=fr_FR.UTF-8 sudo date --set $time
#		echo "=> Setting the Hardware Clock to the current System Time ..."
#		sudo hwclock --systohc
	}
	fi
}
fi

if ! type vim >/dev/null 2>&1; then {
	echo "=> Installation de <vim> et de <firefox-locale-fr> ..."
	$installPackages -y vim firefox-locale-fr
}
fi

type vim >/dev/null 2>&1 && sudo update-alternatives --set editor /usr/bin/vim.basic

if lsusb | grep -qi snapscan; then {
	echo "=> Installation du firmware pour le scanner AGFA SnapScan ..."
	sudo mkdir -p /usr/share/sane/snapscan/
	test -x /usr/share/sane/snapscan/Snape52.bin || sudo install -vp Snape52.bin /usr/share/sane/snapscan/Snape52.bin
	test -x /usr/share/sane/snapscan/snape52.bin || sudo install -vp Snape52.bin /usr/share/sane/snapscan/snape52.bin
	sudo sed -i "s|^firmware .*$|firmware /usr/share/sane/snapscan/Snape52.bin|" /etc/sane.d/snapscan.conf
}
fi

env | grep -q DISPLAY || sudo setupcon

echo "=> Parametrage des formats regionnaux pour la France ..."
if ! grep -q ^LC_ /etc/default/locale; then {
	cat <<-EOF
	#
	LANG="fr_FR.UTF-8"
	LC_NUMERIC="fr_FR.UTF-8"
	LC_TIME="fr_FR.UTF-8"
	LC_MONETARY="fr_FR.UTF-8"
	LC_PAPER="fr_FR.UTF-8"
	LC_IDENTIFICATION="fr_FR.UTF-8"
	LC_NAME="fr_FR.UTF-8"
	LC_ADDRESS="fr_FR.UTF-8"
	LC_TELEPHONE="fr_FR.UTF-8"
	LC_MEASUREMENT="fr_FR.UTF-8"
	LANGUAGE="fr:en"
	EOF
} | sudo tee /etc/default/locale
fi

cdr_device=/dev/sr0
if [ -b $cdr_device ]; then {
	echo "=> Configuration du peripherique de gravure par defaut dans les fichiers </etc/cdrdao.conf> et </etc/environment> ..."
	grep -q CDR_DEVICE /etc/environment  || echo CDR_DEVICE=$cdr_device  | sudo tee -a /etc/environment
	grep -q CDDA_DEVICE /etc/environment || echo CDDA_DEVICE=$cdr_device | sudo tee -a /etc/environment
	test -r /dev/dvd || sudo ln -v -s $cdr_device /dev/dvd

	if [ -f /etc/cdrdao.conf ]; then
		if ! egrep -q "write_device:|read_device:" /etc/cdrdao.conf 2>/dev/null; then {
			cat <<-EOF
			#---/etc/cdrdao.conf --#
			read_device: "/dev/sr0"
			read_driver: "generic-mmc"
			read_paranoia_mode: 3
			#write_buffers: 128
			write_device: "/dev/sr0"
			write_driver: "generic-mmc-raw"
			write_speed: 16
			#cddb_server_list: "http://freedb.freedb.org:80/~cddb/cddb.cgi"
			EOF
		} | sudo tee /etc/cdrdao.conf
		fi
	fi
}
fi

echo "=> Reveil automatique du NetworkManager a la sortie de veille ..."
cat <<EOF | sudo tee /etc/pm/sleep.d/network-manager-wakeup.sh >/dev/null
#!/usr/bin/env sh

case $1 in
    resume|thaw) nmcli nm sleep false;;
esac
EOF

echo "=> Allumage du pave numerique dans LightDM ..."
cat <<-EOF | sudo tee /usr/share/lightdm/lightdm.conf.d/99-numlockx.conf >/dev/null
[SeatDefaults]
greeter-setup-script=/usr/bin/numlockx on
EOF

echo "=> Allumage du pave numerique dans les terminaux virtuels ..."
if ! grep -q setleds /etc/rc.local; then {
	head -n -1 /etc/rc.local
	cat <<-EOF
	INITTY=/dev/tty[1-8]
	for tty in \$INITTY; do
		setleds -D +num < \$tty
	done

	ubuntuBootEntryNumber=\$(efibootmgr | awk '/ubuntu/{gsub("Boot|*","",$1);print \$1}')
#	efibootmgr -b \$ubuntuBootEntryNumber -B
	EFIBootLoadersPartitionNumber=\$(gdisk -l /dev/sda | awk '/\<EF00\>/{print \$1}')
#	efibootmgr -c -d /dev/sda -p \$EFIBootLoadersPartitionNumber -w -L ubuntu -l \\EFI\\ubuntu\\grubx64.efi

	exit 0
	EOF
} | sudo tee /etc/rc.local >/dev/null
fi

declare -a openDNSRelsolverIPs
openDNSRelsolverIP[0]=208.67.222.123
openDNSRelsolverIP[1]=208.67.220.123
gateWay=$(route -n | awk '/^0.0.0.0/{print$2}')

if ! egrep -q "${openDNSRelsolverIP[0]}|${openDNSRelsolverIP[1]}" /etc/dhcp/dhclient.conf; then
	echo "=> Ajout du control parental OpenDNS ..."
	cat <<-EOF > $HOME/dhclient.opendns.patch
--- /etc/dhcp/dhclient.conf       2016-02-15 01:06:30.386755104 +0100
+++ /etc/dhcp/dhclient.conf       2016-02-15 00:17:07.575929346 +0100
@@ -18,6 +18,7 @@
 #send dhcp-client-identifier 1:0:a0:24:ab:fb:9c;
 #send dhcp-lease-time 3600;
 #supersede domain-name "fugue.com home.vix.com";
+supersede domain-name-servers ${openDNSRelsolverIP[0]},${openDNSRelsolverIP[1]},$gateWay #SEB ajout des DNS OpenDNS
 #prepend domain-name-servers 127.0.0.1;
 request subnet-mask, broadcast-address, time-offset, routers,
        domain-name, domain-name-servers, domain-search, host-name,
EOF
	cd / && sudo patch -p0 < $HOME/dhclient.opendns.patch && cd -
	sudo dhclient
fi

if ! grep -q diskfilter.*lvm /etc/grub.d/00_header; then
	echo "=> Patch pour l'erreur diskfilter de grub."
	cat <<-FIN > $HOME/00_header_bug_754921.patch
--- /etc/grub.d/00_header
+++ /etc/grub.d/00_header
@@ -102,23 +102,42 @@ function savedefault {
 EOF

 if [ "\$quick_boot" = 1 ]; then
-    cat <<EOF
+  cat <<EOF
 function recordfail {
   set recordfail=1
 EOF
+
+  check_writable () {
+    abstractions="\$(grub-probe --target=abstraction "\${grubdir}")"
+    for abstraction in \$abstractions; do
+      case "\$abstraction" in
+   diskfilter | lvm)
+     cat <<EOF
+  # GRUB lacks write support for \$abstraction, so recordfail support is disabled.
+EOF
+     return
+     ;;
+      esac
+    done
+
     FS="\$(grub-probe --target=fs "\${grubdir}")"
     case "\$FS" in
       btrfs | cpiofs | newc | odc | romfs | squash4 | tarfs | zfs)
    cat <<EOF
   # GRUB lacks write support for \$FS, so recordfail support is disabled.
 EOF
+   return
    ;;
-      *)
-   cat <<EOF
-  if [ -n "\\\${have_grubenv}" ]; then if [ -z "\\\${boot_once}" ]; then save_env recordfail; fi; fi
-EOF
     esac
+
     cat <<EOF
+  if [ -n "\\\${have_grubenv}" ]; then if [ -z "\\\${boot_once}" ]; then save_env recordfail; fi; fi
+EOF
+  }
+
+  check_writable
+
+  cat <<EOF
 }
 EOF
 fi
FIN
	cd / && sudo patch -p0 < $HOME/00_header_bug_754921.patch && cd -
	sudo chmod +x /etc/grub.d/00_header
#	sudo update-grub
fi

sudo /etc/rc.local

typeset -A firefoxUserPreferenceOtions=([browser.download.manager.showWhenStarting]=false [browser.download.useDownloadDir]=false [privacy.clearOnShutdown.downloads]=false [privacy.clearOnShutdown.history]=false [privacy.sanitize.didShutdownSanitize]=true [privacy.sanitize.sanitizeOnShutdown]=true)

if ! pgrep firefox >/dev/null; then {
	echo "=> Mise a jour des parametres Firefox personalises ..."
	find ~/.mozilla/firefox -type f -name prefs.js | while read firefoxPreferenceFile
	do
		echo "==> firefoxPreferenceFile = $firefoxPreferenceFile"
		{
			for firefoxUserPref in "${!firefoxUserPreferenceOtions[@]}"
			do
				grep -q $firefoxUserPref $firefoxPreferenceFile || echo "user_pref(\"$firefoxUserPref\", ${firefoxUserPreferenceOtions[$firefoxUserPref]});"
				for i in 0 1 2 3 4 5 6
				do
					:
#					grep -q print.tmp.printerfeatures.$printerName.paper.$i.name.*\"A4\" $firefoxPreferenceFile || echo "user_pref(\"print.tmp.printerfeatures.$printerName.paper.$i.name\", \"A4\");"
				done
			done
		} | tee -a $firefoxPreferenceFile
	done
}
fi

languagePackageList=""
languageList="de es pt zh-hans"
for language in $languageList
do
	languagePackageList="$languagePackageList language-pack-$language firefox-locale-$language"
done
dpkg -l | egrep -q "(language-pack-|firefox-locale-)(de|es|pt|zh-hans)" && echo "=> Suppressions des langues: $languageList ..." && $purgePackages $languagePackageList 

if [ -b $cdr_device ]; then {
	type wodim >/dev/null 2>&1 || {
		echo "==> Installation du paquet <wodim> ..."
		$installPackages wodim
	}
	echo "=> Configuration du peripherique de gravure par defaut dans le fichier </etc/wodim.conf> ..."
	sudo touch /etc/wodim.conf
	sudo sed -i "s|^CDR_DEVICE=.*$|CDR_DEVICE=$cdr_device|" /etc/wodim.conf
}
fi

echo "=> Configuration de l'imprimante reseau ..."
printerConfigFile=/etc/cups/printers.conf
sudo touch $printerConfigFile
sudo chmod g+r $printerConfigFile
#PARTIE NESSITANT UNE CONNEXION RESEAU
gateWay=$(route -n | awk '/^0.0.0.0/{print$2}')
networkName=$(dig -x $gateWay +short 2>/dev/null | awk '{print$NF}' | cut -d. -f2-)
echo "=> networkName = $networkName"

case $networkName in
lan.) printerName=LPD-HP-LJ1100
	echo "=> Ajout de l'imprimante $printerName ..."
	if ! grep -q $printerName $printerConfigFile; then {
		cat <<-EOF
		<DefaultPrinter LPD-HP-LJ1100>
		UUID urn:uuid:8cfa9ecf-04df-3975-7435-68c763bd61e6
		Info HP LaserJet 1100 LPD
		Location Home
		DeviceURI lpd://192.168.1.1
		State Idle
		StateTime 1452072271
		Type 8425500
		Accepting Yes
		CM-Calibration No
		Shared No
		JobSheets none none
		QuotaPeriod 0
		PageLimit 0
		KLimit 0
		OpPolicy default
		ErrorPolicy retry-job
		</Printer>
		EOF
} | sudo tee -a $printerConfigFile
fi
;;
*) printerName="" ;;
esac

test -x /etc/cups/ppd/$printerName.ppd || sudo install -vp $printerName.ppd /etc/cups/ppd/

sudo service cups restart

if env | grep -q DISPLAY
then
	type numlockx >/dev/null 2>&1 || {
		echo "==> <numlockx> absent, installation de numlockx ..."
		$installPackages numlockx
	}
  echo "=> Allumage du pave numerique dans l'environement graphique courant ..." && numlockx on
fi

test $distribVersion -gt 10 && frenchPackageList="firefox-locale-fr language-pack-gnome-fr libreoffice-help-fr libreoffice-l10n-fr wfrench" || frenchPackageList="firefox-locale-fr language-pack-gnome-fr openoffice.org-help-fr openoffice.org-l10n-fr wfrench"
test $distribVersion -le 9 && frenchPackageList="language-pack-gnome-fr openoffice.org-help-fr openoffice.org-l10n-fr wfrench"

if ! dpkg -l $frenchPackageList 2>/dev/null | awk '/^ii/{printf "%s ", $2}END {print""}' | sort | grep -q "$frenchPackageList"
#if ! dpkg -l | grep -q libreoffice-l10n-fr
then {
	echo "=> Voulez vous installer la langue francaise ? [O/n]"
	read answer
	if ! echo $answer | egrep -q "n|N"
	then
		echo "=> Installation des paquets: $frenchPackageList"
		$installPackages -y $frenchPackageList
		$cleanPackages
	fi
}
fi

echo "=> Suppression des paquets residuels ..."
sudo apt-get autoremove -q -y

printf "=> Installation des paquets principaux : "
mainPackageList="autoconf libtool lftp fdupes vim sysstat lvm2 curl libxml2 numlockx openssh-server gparted git-core dselect xmlstarlet wodim pdksh nmap"
echo $mainPackageList
$installPackages -y $mainPackageList | grep -v "is already the newest version."
$cleanPackages

if [ $distribRelease != 12.10 ]
then
	echo "=> Ajout du depot VMware pour les VMware Tools ..."
#	grep -q packages.vmware.com /etc/apt/sources.list.d/vmware-tools-$distribCodeName.list 2>/dev/null || echo "deb http://packages.vmware.com/tools/esx/latest/ubuntu $distribCodeName main #VMware Tools" | sudo tee /etc/apt/sources.list.d/vmware-tools-$distribCodeName.list
#	wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub -q -O- | sudo apt-key add -
fi

test $distribVersion -gt 10 && ppaRepositoriesList="ppa:mupdf/stable ppa:sparkers/ppa ppa:rvm/smplayer ppa:jon-severinsson/ffmpeg ppa:qmagneto/ppa ppa:cpug-devs/ppa ppa:nemh/gambas3 ppa:i-nex-development-team/stable ppa:indicator-multiload/stable-daily" || ppaRepositoriesList="ppa:sparkers/ppa ppa:rvm/smplayer ppa:jon-severinsson/ffmpeg ppa:qmagneto/ppa ppa:cpug-devs/ppa ppa:nemh/gambas3 ppa:i-nex-development-team/stable ppa:indicator-multiload/stable-daily ppa:gezakovacs/boost ppa:dnjl/build-multimedia ppa:ripps818/coreavc"
#test $distribVersion -ge 10 && AddRepositories $ppaRepositoriesList

packageList=""
#packageList="gammu grub-pc grub-common html-xml-utils hwinfo pdftk libcdio-utils gnome-media-profiles gstreamer-tools lsdvd lame vorbis-tools conky-all ccze colortail mc cdrdao cdparanoia gdebi gdisk unrar-free cabextract keychain gpm mesa-utils vlock icedax mozplugger deborphan quvi lshw-gtk fsarchiver w3m ksh fping hping3"
#packageList="vim numlockx openssh-server gparted git-core language-pack-gnome-fr gpm system-config-lvm dselect dconf-tools lshw-gtk xmlstarlet fsarchiver flashplugin-installer mozplugger aptitude deborphan firefox firefox-gnome-support firefox-locale-en firefox-locale-fr chromium-browser wodim cdrdao icedax libcdio-utils abcde bashburn xcdroast cdparanoia quvi cclive libav-tools mplayer smplayer"
total=0
for package in $packageList
do
	nbDeps=0
#	nbDeps=$(apt-cache depends $package | grep -wc Depends: || true)
	nbDeps=$(apt-get install $package -s | grep -wc Inst || true)
	total=$(expr $total + $nbDeps)
	echo "=> package = $package"
#	test $nbDeps -gt 10 && {
		printf "==> Nombre de dependances lors de l'installation: "
		echo $nbDeps
		echo
#	}
done
test $total != 0 && echo "=> Le nombre total de paquets necessaires sera de <$total> paquets."

pgrep gpm >/dev/null || {
	type gpm >/dev/null 2>&1 || {
		echo "==> <gpm> absent, installation de gpm ..."
		$installPackages gpm
	}
	echo "=> Demarrage du service <gpm> ..."
	sudo service gpm start
#	sudo gpm -m /dev/input/mouse0 -t ps2
}

which audacious >/dev/null || {
	echo "=> Installation de <audacious> (equivalent de WinAMP) et de <smplayer> ..."
	$installPackages -y audacious smplayer || true
	$cleanPackages
}

test $distribVersion -gt 10 && firefoxPackageList="firefox firefox-globalmenu firefox-gnome-support firefox-locale-en firefox-locale-fr" || firefoxPackageList="firefox firefox-gnome-support firefox-locale-en firefox-locale-fr"
test $distribVersion -le 9 && firefoxPackageList="firefox firefox-globalmenu firefox-gnome-support"
echo "=> MAJ des paquets <$firefoxPackageList> ..."
$installPackages -y $firefoxPackageList
$cleanPackages

test $distribVersion -gt 10 && ppaPackages="indicator-multiload cpu-g i-nex" || ppaPackages="cpu-g i-nex"
test $distribVersion -ge 10 && {
	echo "=> Installation des paquets provenant des PPAs <$ppaPackages> ..."
	$installPackages -y $ppaPackages
	$cleanPackages
}

essentialUniversePackageList="chm2pdf bashdb zsync p7zip-full gammu grub-pc grub-common html-xml-utils hwinfo pdftk libcdio-utils gstreamer-tools lsdvd lame vorbis-tools conky-all ccze mc cdrdao cdparanoia gdebi unrar-free cabextract keychain gpm mesa-utils vlock icedax mozplugger deborphan quvi lshw-gtk fsarchiver w3m ksh fping hping3"
test $distribVersion -gt 10 && essentialUniversePackageList="mupdf gnome-media-profiles colortail gdisk $essentialUniversePackageList" || essentialUniversePackageList="mupdf colortail gdisk $essentialUniversePackageList"

echo "=> Installation des paquets essentiels Universe/Multiverse <$essentialUniversePackageList> ..."
$installPackages -y $essentialUniversePackageList
$cleanPackages

case $distribRelease in
	12.10) compizPackageList="compizconfig-settings-manager compiz-plugins-main compiz-plugins-extra";;
	10.04|10.10|11.04|11.10|12.04) compizPackageList="compizconfig-settings-manager compiz-fusion-plugins-main compiz-fusion-plugins-extra";;
esac

which ccsm >/dev/null || {
	echo "=> Installation de <$compizPackageList> ..."
	$installPackages -y $compizPackageList || true
}

which sound-juicer >/dev/null || {
	echo "=> Installation de <sound-juicer gstreamer0.10-plugins-ugly gstreamer0.10-plugins-bad> ..."
	$installPackages sound-juicer gstreamer0.10-plugins-ugly gstreamer0.10-plugins-bad || true
}

test $distribVersion -gt 9 && universePackageList="alacarte aptitude system-config-lvm dconf-tools chromium-browser libcdio-utils abcde bashburn cclive w3m-img" || universePackageList="alacarte aptitude system-config-lvm chromium-browser libcdio-utils abcde cclive w3m-img"
echo "=> Installation des paquets: $universePackageList ..."
$installPackages $universePackageList | grep -v "is already the newest version."
$cleanPackages

multiversePackageList="flashplugin-installer p7zip-rar"
echo "=> Installation des paquets Multiverse: $multiversePackageList ..."
$installPackages $multiversePackageList
$cleanPackages

if [ $(echo $distribRelease | cut -d. -f1) -ge 12 ]
then
	if ! dpkg -l | egrep -q browser-plugin-lightspark
	then
		echo "=> Voulez vous installer <browser-plugin-lightspark> version:$(apt-cache --no-all-versions show browser-plugin-lightspark | awk -F": " '/Version:/{print$2}'), cela necessite de telecharger 62 paquets pour 120Mo d'espace disque dans /usr et 67Mo dans /var/cache/apt, [O/n] ?"
		read answer
		if ! echo $answer | egrep -q "N|n"
		then
			$purgePackages flashplugin-installer
			$installPackages -y browser-plugin-lightspark p7zip-rar
		fi
		$cleanPackages
	fi
fi

test $distribVersion -gt 9 && additionnalPackageList="ffmpeg libav-tools mplayer2 smplayer quvi cclive w3m-img wammu auto-apt" || additionnalPackageList="ffmpeg ffprobe mplayer smplayer quvi cclive w3m-img wammu auto-apt"
echo "=> Telechargement des paquets additionnels: $additionnalPackageList ..."
$installPackages -d $additionnalPackageList
echo "=> Installation des paquets additionnels: $additionnalPackageList ..."
$installPackages -qq $additionnalPackageList
$cleanPackages

type apt-file >/dev/null 2>&1 || {
	echo "=> Installation du paquet <apt-file> ..."
	$installPackages -y apt-file
	$cleanPackages
	sudo apt-file update
}

setMimes

notToBeErasedPackageList="pdksh,libav-tools,jockey-gtk,compiz-plugins-main-default,compiz-plugins-main,compiz-plugins-extra,compiz-fusion-plugins-main,compiz-fusion-plugins-extra"
test "$(deborphan -e $notToBeErasedPackageList)" && echo "=> Suppressions des paquets orphelins : <$(deborphan -e $notToBeErasedPackageList) ..." && $purgePackages $(deborphan -e $notToBeErasedPackageList)
echo "=> Fin."
