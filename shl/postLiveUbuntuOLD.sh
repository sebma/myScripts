#!/usr/bin/env bash

set -o errexit
set -o nounset

LANG=C

AddUbuntuRepository() {
	repositoryName=$1
	distribCodeName=$(lsb_release -sc)
	distribRelease=$(lsb_release -sr)
	distribVersion=$(echo $distribRelease | cut -d. -f1)

	echo
	echo "=> Ajout des depots Ubuntu ..."
	echo "==> Ajout du depot <$repositoryName> ..."
	if [ $distribVersion -gt 10 ]
	then
		sudo add-apt-repository "deb http://fr.archive.ubuntu.com/ubuntu/  $distribCodeName $repositoryName"
	else
		sudo add-apt-repository "http://fr.archive.ubuntu.com/ubuntu/ $repositoryName"
	fi
	
	sudo add-apt-repository "deb http://security.ubuntu.com/ubuntu/ $distribCodeName-security $repositoryName"
	sudo add-apt-repository "deb http://fr.archive.ubuntu.com/ubuntu/  $distribCodeName-updates $repositoryName"
	
	echo "==> Desactivation de la source de type CD/DVD-ROM ..."
	sudo sed -i "/^deb cdrom/s/^/# /" /etc/apt/sources.list
	echo "==> Choix des mirroirs Francais pour la proximite ..."
	sudo sed -i "/\/archive.ubuntu.com/s/archive.ubuntu.com/fr.archive.ubuntu.com/" /etc/apt/sources.list
	
#	echo "==> Ajout du depot Ubuntu Partner :"
#	if [ $distribRelease = 10.04 ]
#	then
#		sudo add-apt-repository "deb http://archive.canonical.com/ $distribCodeName partner"
#	else
#		sudo add-apt-repository "http://archive.canonical.com/ubuntu/ partner"
#	fi

	echo "==> Suppression des depots sources ..."
	sudo sed -i "/deb-src/d" /etc/apt/sources.list
}

AddLaunchpadRepositories() {
	echo "==> Ajout des depots Launchpad PPA ..."
	for ppa
	do
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
	done
	sudo sed -i "/deb-src/d" /etc/apt/sources.list.d/*.list

	apt-cache show smplayer >/dev/null 2>&1 || {
		echo "=> Mise a jour de la liste des paquets presents dans les depots logiciels, cela dure environ 60 secondes ..."
		$(which time) -p sudo apt-get update -qq || true
	}
}

if ! test -x $0
then
  chmod u+x $0 || sudo chmod u+x $0
fi

interpreter=$(ps -o pid,comm | awk /$$/'{print $2}')
test $interpreter != bash && {
  echo "=> Mauvais interpreteur (interpreter = $interpreter), veuillez relancer le script $(basename $0) de la maniere suivante: ./$0" >&2
  return 127
}

mkdir -p $HOME/.gnupg
isLinux=$(uname -s | grep -q Linux && echo true || echo false)
distribName=""
if $($isLinux)
then
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
else
	distribName=Unix
	echo "=> This script only runs on Linux." >&2
	exit 1
fi

case $distribName in
ubuntu|debian)
	installPackages="sudo apt-get install -V"
	purgePackages="sudo apt-get purge -qq -y"
	cleanPackages="sudo apt-get clean"
	distribRelease=$(lsb_release -sr)
;;
*)
	echo "=> ERROR: This script must be run on Ubuntu Linux." >&2
	exit 1
;;
esac

#Ouvrir les fichiers documents avec LibreOffice
which libreoffice >/dev/null 2>&1 && {
	documentFileTypes=".doc .docx .sxw .odt .xls .xlsx .sxc .ods .ppt .pps .pptx .ppsx .sxi .odp"
	documentMimeTypes="$(mimetype -b $documentFileTypes | sort | xargs)"
	xdg-mime default libreoffice-startcenter.desktop $documentMimeTypes
	echo "=> Les fichiers $documentFileTypes s'ouvriront desormais avec <libreoffice>."
}

#Ouvrir les fichiers Audio avec audacious
which audacious >/dev/null 2>&1 && {
	audioFileTypes=".wav .wma .aac .ac3 .mp2 .mp3 .ogg .oga .m4a"
	audioMimeTypes="$(mimetype -b $audioFileTypes | grep audio | sort | xargs) audio/x-vorbis+ogg"
	xdg-mime default audacious.desktop $audioMimeTypes
	echo "=> Les fichiers $audioFileTypes s'ouvriront desormais avec <audacious>."
}

#Ouvrir les fichiers Video avec SMPlayer
which smplayer >/dev/null 2>&1 && {
	videoFileTypes=".asf .avi .wmv .mpg .mpeg .mp4 .divx .flv .mov .ogv .webm .vob .ts .m2ts .3gp .mkv"
	videoMimeTypes=$(mimetype -b $videoFileTypes | grep video | sort | xargs)
	xdg-mime default smplayer.desktop $videoMimeTypes
	echo "=> Les fichiers $videoFileTypes s'ouvriront desormais avec <smplayer>."
}

#Ouvrir les fichiers .deb avec gdebi-gtk
which gdebi-gtk >/dev/null 2>&1 && xdg-mime default gdebi.desktop application/x-deb

env | grep -q DISPLAY && {
	echo "=> Chargement du clavier francais pour la session graphique courante ..."
	setxkbmap fr
	echo "=> Type de clavier :"
	setxkbmap -print | awk -F'"' '/geometry/{print$2}'
}

echo "=> Chargement du clavier francais dans les terminaux virtuels ..."
sudo loadkeys fr-latin9 || true

grep -q "set ts" $HOME/.exrc 2>/dev/null || echo set ts=2 >> $HOME/.exrc
grep -q "set ai" $HOME/.exrc 2>/dev/null || echo set ai >> $HOME/.exrc

env | grep -q DISPLAY && {
	currentResolution=$(xrandr | awk -F" *|\+" '/ connected/{print $3}')
	echo "=> La resolution courrante est : $currentResolution"
	if [ $currentResolution = 800x600 ] || [ $currentResolution = 640x480 ]
	then
		echo "=> Augmentation de la resolution graphique ..."
		xrandr -s 1024x768
		printf "==> La nouvelle resolution est : "
		xrandr | awk -F" *|\+" '/ connected/{print $3}'
		grep -q "xrandr -s" /etc/X11/Xsession.d/45x11-xrandr 2>/dev/null || echo xrandr -s 1024x768 | sudo tee -a /etc/X11/Xsession.d/45x11-xrandr
	fi
}

franceTimeZone=Europe/Paris
if ! grep -q $franceTimeZone /etc/timezone
then
	echo "=> Configuration du Fuseau horaire <$franceTimeZone> ..."
	echo $franceTimeZone | sudo tee /etc/timezone
fi

if ! grep -q "TZ=." /etc/environment
then
	echo TZ=$franceTimeZone | sudo tee -a /etc/environment
fi
#sudo dpkg-reconfigure tzdata

for group in video saned lp dialout
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
echo $answer | egrep -q "N|n" && {
	echo "=> Syncronisation de l'horloge avec les serveurs de temps, cela dure environ 10 secondes ..."
	$(which time) -p sudo ntpdate ntp.ubuntu.com pool.ntp.org || {
		echo "==> Les serveurs NTP: ntp.ubuntu.com et pool.ntp.org ne sont pas accessibles d'ici, veuillez saisir l'heure locale sous la forme HH:MM"
		read time
		echo $time | grep -q "^[0-9][0-9]:[0-9][0-9]$" || {
		  echo "==> ERREUR: L'heure saisie est invalide" >&2
			exit 2
		}

		printf "=> The date is now: "
		TZ=$franceTimeZone LANG=fr_FR.UTF-8 sudo date --set $time
#		echo "=> Setting the Hardware Clock to the current System Time ..."
#		sudo hwclock --systohc
	}
}

type vim >/dev/null 2>&1 || {
	echo "=> Installation de <vim> et de <firefox-locale-fr> ..."
	$installPackages -y vim firefox-locale-fr
}

lsusb | grep -qi snapscan && {
	echo "=> Installation du firmware pour le scanner AGFA SnapScan ..."
	sudo mkdir -p /usr/share/sane/snapscan/
	test -x /usr/share/sane/snapscan/Snape52.bin || sudo install -vp Snape52.bin /usr/share/sane/snapscan/Snape52.bin
	test -x /usr/share/sane/snapscan/snape52.bin || sudo install -vp Snape52.bin /usr/share/sane/snapscan/snape52.bin
	sudo sed -i "s|^firmware .*$|firmware /usr/share/sane/snapscan/Snape52.bin|" /etc/sane.d/snapscan.conf
}

grep -q DISPLAY /etc/profile || {
	cat <<-EOF
	env | grep -q DISPLAY || export LANG=C
	EOF
} | sudo tee -a /etc/profile

echo "=> Configuration du clavier francais de maniere definitive ..."
test -f /etc/default/keyboard && {
	sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="fr"/' /etc/default/keyboard
	sudo sed -i 's/^XKBOPTIONS=.*/XKBOPTIONS="terminate:ctrl_alt_bksp"/' /etc/default/keyboard
}
env | grep -q DISPLAY || sudo setupcon
#echo setxkbmap fr >> $HOME/.xinitrc
#chmod u+x $HOME/.xinitrc
sudo udevadm trigger --subsystem-match=input --action=change

echo "=> Parametrage des formats regionnaux pour la France ..."

grep -q ^LC_ /etc/default/locale || {
	cat <<-EOF
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

grep -q ^LC_.*=. /etc/environment || cat /etc/default/locale | sudo tee -a /etc/environment

cdr_device=/dev/sr0
test -b $cdr_device && {
	echo "=> Configuration du peripherique de gravure par defaut dans les fichiers </etc/cdrdao.conf> et </etc/environment> ..."
	grep -q CDR_DEVICE /etc/environment  || echo CDR_DEVICE=$cdr_device  | sudo tee -a /etc/environment
	grep -q CDDA_DEVICE /etc/environment || echo CDDA_DEVICE=$cdr_device | sudo tee -a /etc/environment
	test -r /dev/dvd || sudo ln -v -s $cdr_device /dev/dvd
	
	egrep -q "write_device:|read_device:" /etc/cdrdao.conf 2>/dev/null || {
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
}

echo "=> Allumage du pave numerique dans les terminaux virtuels ..."
grep -q setleds /etc/rc.local || {
	head -n -1 /etc/rc.local
	cat <<-EOF
	INITTY=/dev/tty[1-8]
	for tty in \$INITTY; do
		setleds -D +num < \$tty
	done

	exit 0
	EOF
} | sudo tee /etc/rc.local
sudo /etc/rc.local

echo "=> Mise a jour des alias dans </etc/bash.bashrc> ..."
grep -qw alias /etc/bash.bashrc || {
	cat <<-EOF
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias apt-get="\apt-get -V"
alias aptitude="\aptitude -V"
alias bc="\bc -l"
alias cclive="\cclive -c"
alias cdda_info="\icedax -gHJq -vtitles"
alias cdrdao='\df | grep -q \$CDR_DEVICE && umount -vv \$CDR_DEVICE ; \cdrdao'
alias checkcertif="\openssl verify -verbose"
alias checkcer="\openssl x509 -noout -inform PEM -in"
alias checkcrt="\openssl x509 -noout -inform PEM -in"
alias checkder="\openssl x509 -noout -inform DER -in"
alias clearurlclassifier3="\find . -type f -name urlclassifier3.sqlite -exec rm -vf {} \;"
alias cp="\rsync -u -zPt --skip-compress=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp[234]/vob/ts/ogg/rpm/tbz/tgz/z/zip"
alias cpuUsage="mpstat | tail -1 | awk '{print 100-\\\$NF}'"
type cleartool >/dev/null 2>&1 && alias ct=cleartool
alias df="\df -h"
alias dos2unix='\perl -pi -e "s/\r//g"'
alias doublons='\fdupes -rd .'
alias du="LANG=C \du -h"
alias eject='sudo \eject'
alias ejectcd='\eject \$CDR_DEVICE'
alias closecd='\eject -t \$CDR_DEVICE'
alias eman="\man -L en"
alias errors="\egrep -iC2 'error|erreur|java.*exception'"
alias free="\free -m"
alias fuser="\fuser -v"
alias gunzip="\gunzip -Nv"
alias gzcat="\gunzip -c"
alias gzgrep="\zgrep ."
alias gzip="\gzip -Nv"
alias halt="\halt && exit"
alias hexdump="\od -ctx1"
alias html2xml="\xmlstarlet format --quiet --html --recover --indent-tab"
alias integer="typeset -i"
alias lastfiles="\find . -type f -mmin -2 -exec ls -l --time-style=+"%H:%M:%S" {} \;"
alias ls="\ls --color -F"
alias lsdvd="\lsdvd -avc"
alias lshw="\lshw -numeric -sanitize"
#alias ll="LANG=C ls -lh"
alias ll="ls -lh"
#alias loadsshkeys='eval \$(ssh-agent -s) && ssh-add'
alias loadsshkeys='eval \$(keychain --eval --agents ssh)'
alias lspci="\lspci -nn"
alias lxterm="\lxterm -sb -fn 9x15"
alias memUsage="free -m | awk '/^Mem/{print 100*\\\$3/\\\$2}'"
alias mv="\mv -iv"
alias mysed="\perl -p"
alias nautilus="\nautilus --no-desktop"
alias od="\od -ctx1"
alias page="\head -50"
alias pcmanfm="\pcmanfm --no-desktop"
alias pgrep="\pgrep -f"
#alias pkill="\pkill -f"
#alias ports="sudo \lsof -ni -P | grep LISTEN"
alias ports="\netstat -ntl"
#alias processUsage="ps -eorss,args | sort -nr | cut -c-156 | head"
#alias processUsage="ps -eorss,args | sort -nr | head -100 | awk '{print \\\$1/1024\"MiB \" \\\$2}'"
alias processUsage="echo '  RSS  %MEM  %CPU COMMAND';\ps -e -o rssize,pmem,pcpu,args | sort -nr | cut -c-156 | head -500 | awk '{printf \"%9.3fMiB %4.1f%% %4.1f%% %s\n\", \\\$1/1024, \\\$2,\\\$3,\\\$4}'"
alias ps="\ps -f"
alias psu='\ps -fu \$USER'
alias putty="\putty -geometry 157x53 -l \$USER -t -A -C -X"
alias reboot="\reboot && exit"
alias recode="\recode -v"
alias rename="\rename -v"
alias repeat="\watch -n1"
alias restart_conky="\killall -SIGHUP conky"
alias rm="\rm -iv"
#alias scp="\scp -pC"
alias scp="\rsync -u -zPt --skip-compress=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp[234]/ogg/rpm/tbz/tgz/z/zip"
alias scp_unix='\rsync --rsync-path=\$HOME/gnu/bin/rsync -uPt'
alias sdiff='\sdiff -w \$(tput cols)'
alias ssh="\ssh -t -A -C -Y"
alias sum="awk '{sum+=\\\$1}END{print sum}'"
alias swapUsage="free -m | awk '/^Swap/{print 100*\\\$3/\\\$2}'"
alias sudo="\sudo "
alias terminfo='echo "=> C est un terminal $(tput cols)x$(tput lines)."'
alias timestamp='date +"%Y%m%d_%HH%M"'
alias today="\find . -type f -ctime -1 -ls"
alias topd10="\du -xsm */ .??*/ | sort -nr | head -10"
alias topd5="\du -xsm */ .??*/ | sort -nr | head -5"
alias topd="\du -xsm */ .??*/ | sort -nr | head -n"
alias topf10="\find . -xdev -type f -size +10M -exec ls -lh {} \; 2>/dev/null | sort -nrk5 | head -10"
alias topf5="\find . -xdev -type f -size +10M -exec ls -lh {} \; 2>/dev/null | sort -nrk5 | head -5"
alias topf="\find . -xdev -type f -size +10M -exec ls -lh {} \; 2>/dev/null | sort -nrk5 | head -n"
#alias umount="\umount -vv"
alias uncompress="\uncompress -v"
alias uncpio="\cpio -idcmv <"
alias unix2dos='\perl -pi -e "s/\n/\r\n/g"'
alias update="time sudo apt-get update -q"
alias upgrade="sudo apt-get upgrade"
alias urlinfo='\quvi -v mute --exec "ffprobe %u"'
alias urlplayer='\quvi -v mute --exec "mplayer -quiet %u"'
alias unjar="\unzip"
alias untar="\tar -xvf"
alias wavemon="\lxterminal -e wavemon &"
alias wget="\wget -c"
alias xclock="\xclock -digital -update 1"
alias xfree="\xterm -geometry 73x5 -e watch -n2 free -om &"
type xpath >/dev/null 2>&1 && alias xpath="perl -lw \$(which xpath)"
alias xprop='\xprop | egrep "WM_CLASS|PID|\<WM_ICON_NAME"'
alias viewcer="\openssl x509 -noout -text -inform PEM -subject -issuer -dates -purpose -nameopt multiline -in"
alias viewcrt="\openssl x509 -noout -text -inform PEM -in"
alias viewcsr="\openssl req -noout -text -inform PEM -in"
alias viewder="\openssl x509 -noout -text -inform DER -in"
alias xterm="\xterm -sb -fn 9x15"

EOF
} | sort | sudo tee -a /etc/bash.bashrc

echo "=> Mise a jour des fonctions dans </etc/bash.bashrc> ..."
grep -qw wav2mp3 /etc/bash.bashrc || {
	cat <<-EOF
2utf8() {
  file=\$1
  test \$file && recode -v \$(file -i \$file | cut -d= -f2)..utf8 \$file
}
any2mkv() {
  for file
  do
    ffmpeg -i "\$file" -f mkv -vcodec copy -acodec copy "\${file%.???}.mkv" || break
  done
}
any2mp3() {
  for file
  do
    if ffprobe "\$file" 2>&1 | grep -q "Audio: mp3"
    then
      ffmpeg -i "\$file" -vn -acodec copy "\${file%.???}.mp3" || break
    fi
  done
}
audioFormat() {
  for file
	do
	  audioFormat=\$(ffprobe "\$file" 2>&1 | awk '/Audio/{print\$4}' | sed "s/,\$//")
    test \$audioFormat = vorbis && format=ogg || format=\$audioFormat
    echo \$format
	done
}
containsmp3file() {
  for file
  do
    echo
    echo "=> file = \$file"
    if ffprobe "\$file" 2>&1 | egrep -q "Stream .*Audio.*(mp3)"
    then
      echo "=> File <\$file> contains a mp3 stream:"
      ffprobe "\$file" 2>&1 | egrep -w "Input|Duration:|Stream"
      true
    else
      echo "=> \$file does not contain any mp4 stream."
      false
    fi
  done
}
containsmp3stream() {
  format=best
  echo \$1 | grep -q ^http || {
    format=\$1
    shift
  }
  echo
  for url
  do
    echo "=> url = \$url"
    if \quvi -vm -f \$format --exec "ffprobe %u 2>&1" "\$url" | egrep -q "Stream .*Audio.*(mp3)"
    then
      echo "=> It contains a mp3 stream."
      echo
    else
      echo "=> \$url does not contain any mp3 stream."
      echo
      false
    fi
  done
}
containsmp4file() {
  for file
  do
    echo
    echo "=> file = \$file"
    if ffprobe "\$file" 2>&1 | egrep -q "Stream .*Video.*(h264)"
    then
      echo "=> File <\$file> contains a mp4 stream:"
      ffprobe "\$file" 2>&1 | egrep -w "Input|Duration:|Stream"
      true
    else
      echo "=> \$file does not contain any mp4 stream."
      false
    fi
  done
}
containsmp4stream() {
  format=best
  echo \$1 | grep -q ^http || {
    format=\$1
    shift
  }
  echo
  for url
  do
    echo "=> url = \$url"
    if \quvi -vm -f \$format --exec "ffprobe %u 2>&1" "\$url" | egrep -q "Stream .*Video.*(h264)"
    then
      echo "=> It contains a mp4 stream."
      echo
    else
      echo "=> \$url does not contain any mp4 stream."
      echo
      false
    fi
  done
}
cpio2tgz() {
  set -eu
  for file
  do
    dirList=\$(cpio -it < \$file | cut -d/ -f1 | sort -u)
    cpio -id < \$file && tar -c \$dirList | gzip -9c > \$(basename \$file .cpio).tgz && rm -fr \$dirList
  done
}
delExtension() {
  firstFile=\$1
  extension=\$(echo "\$firstFile" | awk -F. '{print \$NF}')
  rename -v "s/\.\$extension\$//" *.\$extension
}
getaudio() {
  for tool in ffmpeg ffprobe
  do
    type \$tool >/dev/null || {
      echo "=> ERROR: <\$tool> is not installed." >&2
      return 1
    }
  done
  echo \$LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d \$musicDir || mkdir \$musicDir
  for file
  do
    extension=\$(echo "\$file" | awk -F. '{print\$NF}')
    audioFormat=\$(ffprobe "\$file" 2>&1 | awk '/Audio/{print\$4}' | sed "s/,\$//")
    test \$audioFormat = vorbis && format=ogg || format=\$audioFormat
    format=\$(audioFormat "\$file")
    output=\$musicDir/\$(basename "\$file" .\$extension).\$format
    ffmpeg -i "\$file" -vn -acodec copy "\$output"
    echo
    test -s "\$output" && echo "=> Output file is: <\$output>."
  done
}
get_extension_id() {
# Retrieve the extension id for an addon from its install.rdf
	for xpi
	do
	  echo "=> xpiFile = \$xpi"
	  unzip -qc \$xpi install.rdf | xmlstarlet sel \\
    -N rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns# \\
    -N em=http://www.mozilla.org/2004/em-rdf# \\
    -t -v \\
    "//rdf:Description[@about='urn:mozilla:install-manifest']/em:id"
	done
}
get_extension_name() {
# Retrieve the extension name for an addon from its install.rdf
	for xpi
	do
	  echo "=> xpiFile = \$xpi"
	  unzip -qc \$xpi install.rdf | xmlstarlet sel \\
    -N rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns# \\
    -N em=http://www.mozilla.org/2004/em-rdf# \\
    -t -v \\
    "//rdf:Description[@about='urn:mozilla:install-manifest']/em:name"
	done
}
getmp4() {
  for tool in cclive quvi ffprobe
  do
    type \$tool >/dev/null || {
      echo "=> ERROR: <\$tool> is not installed." >&2
      return 1
    }
  done
  echo
  for url
  do
    echo
    echo "=> url = <\$url>"
    fileBaseName="\$(\cclive -n \$url 2>&1 | egrep "video/|application/octet-stream" | cut -d. -f1).mp4"
    if [ -s "\$fileBaseName" ]
    then
      echo "==> <\$fileBaseName> is already downloaded."
    else
      if quvi -v mute --exec "ffprobe %u" "\$url" 2>&1 | egrep -q "Video: (h264|mp4)"
      then
        echo "==> <\$url> contains a mp4 video stream."
        \cclive -c \$url --exec "any2mp4 \"%n\""
      else
        echo "==> WARNING: <\$url> does not contain any mp4 stream, skipping ..."
      fi
    fi
  done
}
getmp4() {
  for tool in cclive quvi ffprobe
  do
    type \$tool >/dev/null || {
      echo "=> ERROR: <\$tool> is not installed." >&2
      return 1
    }
  done
  echo
  for url
  do
    if containsmp4stream \$url >/dev/null
    then
      echo "=> <\$url> contains a mp4 stream."
      echo
      \cclive -c \$url >/dev/null
    else
      echo "=> <\$url> does not contain any mp4 stream."
      echo
      false
    fi
  done
}
getRealURL() {
  url=\$1
  test \$# = 2 && format=\$2 || format=best
  real_url=\$(\quvi -vm -f \$format "\$url" --exec "echo %u")
  test \$real_url && echo "=> real_url = \$real_url"
}
locate() {
  echo "\$@" | grep -q "\-[a-z]*r" && \$(which locate) "\$@" || \$(which locate) -i "*\${@}*"
}
mediaInfoSummary() {
  for media
  do
    mediainfo "\$media" | \egrep "^Complete name|^Format  |^Format version|^Format profile| size|^Duration|^Video|^Audio|Kbps"
    echo
  done
}
mplayer() {
  if tty | grep -q "/dev/pts/[0-9]"
  then
    \$(which mplayer) -idx -quiet -geometry 0%:100% "\$@" 2>/dev/null | egrep "stream |Track |VIDEO:|AUDIO:|VO:|AO:"
  else
    if [ -c /dev/fb0 ]
    then
      if [ ! -w /dev/fb0 ]
    then
        groups | grep -wq video || sudo adduser \$USER video
        sudo chmod g+w /dev/fb0
      fi
      \$(which mplayer) -vo fbdev2 -idx -quiet "\$@" 2>/dev/null | egrep "stream |Track |VIDEO:|AUDIO:|VO:|AO:"
    else
      echo "=> Function \$FUNCNAME - ERROR: Framebuffer is not supported in this configuration." >&2
      return 1
    fi
  fi
}
pcclive() {
  for file
  do
    \cclive -bc \$file
    while read line
    do
      \cclive -bc \$line
    done < \$file
  done
}
type pkill >/dev/null 2>&1 && pkill() {
  arg1=\$1
  echo "=> Before :"
  \pgrep -u \$USER -lf \$arg1
  echo \$arg1 | grep -q "\-[0-9A-Z]" && {
    shift
    \$(which pkill) \$arg1 -f \$@
  } || \$(which pkill) -f \$@
  sleep 1
  echo "=> After :"
  \pgrep -u \$USER -lf \$arg1
}
rpm2tgz() {
  set -eu
  for file
  do
    cpio_file=\$(basename \$file .rpm).cpio
    rpm2cpio \$file > \$cpio_file && \rm -v \$file
    cpio2tgz \$cpio_file && \rm -v \$cpio_file
  done
}
sizeof() {
  local size
  local total="0"
  for url
  do
    size=\$(\quvi -vq -f best --xml \$url | xmlstarlet format -R 2>/dev/null | xmlstarlet select -t -v "//length_bytes/text()" | awk '{print \$0/2^20}')
    total="\$total+\$size"
    printf "%s %s Mo\n" \$url \$size
  done
  total=\$(echo \$total | \bc -l)
  echo "=> total = \$total Mo"
}	
splitaudio() {
  if [ \$# != 2 ] && [ \$# != 3 ]
  then
    echo "=> Usage: \$0 <filename> hh:mm:ss[.xxx] [ hh:mm:ss[.xxx] ]"
    return 1
  fi

  fileName="\$1"
  extension=\$(echo \$fileName | sed "s/^.*\.//")
  fileBaseName=\$(basename "\$fileName" .\$extension)
  begin=\$2
  test \$# = 3 && {
    end=\$3
    ffmpeg -i "\$fileName" -ss \$begin -to \$end -vn -acodec copy "\$fileBaseName-CUT.\$extension"
  } || {
#   end=\$(ffmpeg -i "\$fileName" 2>&1 | awk -F",| *" '/Duration:/{print\$3}')
    ffmpeg -i "\$fileName" -ss \$begin -vn -acodec copy "\$fileBaseName-CUT.\$extension"
  }
}
type tgz >/dev/null 2>&1 || tgz() {
  test \$1 && {
    archiveFileName=\$1
    shift
    tar -cv \$@ | gzip -9 > \$archiveFileName
  }
}
umount() {
  for arg
  do
    \fuser -v \$arg 2>&1 | grep \$USER || \$(which umount) -vv \$arg
  done
}
untgz() {
  archive="\$1"
  echo "=> Uncompression and unarchiving the \$archive compressed archive ..."
  gunzip -v \$archive || {
    echo "ERROR : The file  \$archive is an unvalid gzip  format." >&2
    exit 1
  } 
  tar -tf \$(basename \$archive .gz) >/dev/null || {
    echo "ERROR : The file  \$archive is an unvalid tar archive." >&2
    exit 2
  }
  tar -xvf \$(basename \$archive .gz)
}
updatemp4tags() {
  for file
  do
    echo "=> file = " \$file
    test ! -f "\$file" && echo "=> ERROR: File <\$file> does not exist." 2>&1 && continue
    AtomicParsley "\$file" -t | grep "Atom.*nam.*contains:" && echo "=> ERROR: File <\$file> already has the filename metadata." 2>&1 && continue
    fileBase=\$(basename "\$file")
    freeSpace=\$(\df -Pk "\$file" | awk '/dev|tmpfs/{print int(\$4)}')
    fileSize=\$(\ls -l "\$file" | awk '{print int(\$5/1024)}')
    if [ \$freeSpace -lt \$fileSize ]
    then
      \mv -v "\$file" /tmp
      AtomicParsley "/tmp/\$fileBase" --output "\$file" --title "\$fileBase"
    else
      AtomicParsley "\$file" --overWrite --title "\$fileBase"
    fi
    AtomicParsley "\$file" -t
  done
}
vacuum() {
#  find . -name "*sqlite" -ls -exec sqlite3 {} vacuum \;
  find . -name "*sqlite" | while read file
  do
#    echo file=\$file
    mv \$file /tmp/
    echo "=> sqlite3 /tmp/\$(basename \$file) vacuum; ..."
    sqlite3 /tmp/\$(basename \$file) 'vacuum;'
    mv /tmp/\$(basename \$file) \$file
  done
}
videoFormat() {
  for file
  do
    videoFormat=\$(ffprobe "\$file" 2>&1 | awk '/Video/{print\$4}' | sed "s/,\$//")
    format=\$videoFormat
    echo \$format
  done
}
vidinfo() {
  for video
  do
    ffprobe "\$video" 2>&1 | egrep "Seems|Input|Duration:|Stream|Unknown"
    echo
  done
}
vidurlinfo() {
  format=best
  echo \$1 | grep -q ^http || {
    format=\$1
    shift
  }
  echo
  for url
  do
    echo "=> url = \$url"
    echo
    \quvi -vm -f \$format --exec "ffprobe %u 2>&1" "\$url" | egrep "Seems|Input|Duration:|Stream|Unknown"
    echo
  sizeof "\$url"
  done
}
wav2mp3() {
  echo \$LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d \$musicDir || mkdir \$musicDir
  for file
  do
    output=\$musicDir/\$(basename "\$file" .wav).mp3
    lame -v --replaygain-accurate "\$file" "\$output"
  done
}
wav2ogg() {
  echo \$LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d \$musicDir || mkdir \$musicDir
  for file
  do
    output=\$musicDir/\$(basename "\$file" .wav).ogg
    oggenc -q4 "\$file" -o "\$output"
  done
}
wma2wav() { 
  echo \$LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d \$musicDir || mkdir \$musicDir
  for file
  do
    output=\$musicDir/\$(basename "\$file" .wma).wav
    ffmpeg -i "\$file" "\$output"
  done
}
xmlcheck() {
  test \$# -lt 1 && {
    echo "=> Usage: \$FUNCNAME [file1] [file2] ..." >&2
    return 1
  }

  type xmlstarlet >/dev/null 2>&1 && xmlCheckTool="xmlstarlet validate --err" || xmlCheckTool="xml -c"

  for file
  do
    printf "=> \$xmlCheckTool \$file... "
    \$xmlCheckTool \$file && echo OK.
  done
}
xmlindent() {
  test \$# -lt 1 && {
    echo "=> Usage: \$FUNCNAME [file1] [file2] ..." >&2
    return 1
  }

  type xmllint >/dev/null 2>&1 && {
    xmlIndentTool="\xmllint --format"
    encodingOption="--encode"
  } || {
    xmlIndentTool="xml -PP"
    encodingOption="-e"
  }

  for file
  do
    inputFileEncoding=\$(awk -F "'|\"" '/xml.*version.*encoding.*=/{print \$4;}' \$file)
    echo "=> inputFileEncoding = <\$inputFileEncoding>" >&2
    test \$inputFileEncoding && {
      echo "=> \$xmlIndentTool \$encodingOption \$inputFileEncoding \$file ..."
      \$xmlIndentTool \$encodingOption \$inputFileEncoding \$file | tee \$file.indented
      echo "=> The indented file is <\$file.indented>."
    }
  done
}
xmlvalidate() {
  test \$# -lt 2 && {
    echo "=> Usage: \$FUNCNAME <xsd scheme> [file1] [file2] ..." >&2
    return 1
  }

  type xmllint >/dev/null 2>&1 && xmlValidationTool="xmllint --noout --schema"
  type xmlstarlet >/dev/null 2>&1 && xmlValidationTool="xmlstarlet validate --err --xsd"

  test "\$xmlValidationTool" || {
    echo "=> ERROR[Function \$FUNCNAME]: There is neither <xmllint> nor <xmlstarlet> installed on <\$(hostname)>." >&2
    return 2
  }

  local xsd_scheme=\$1
  shift

  for file
  do
    echo "=> \$xmlValidationTool \$xsd_scheme \$file ..."
    \$xmlValidationTool \$xsd_scheme "\$file"
  done
}
ytgetmp3() {
  for tool in cclive quvi ffprobe
  do
    type \$tool >/dev/null || {
      echo "=> ERROR: <\$tool> is not installed." >&2
      return 1
    }
  done
  echo
  for url
  do
    echo "\$url" | grep -q youtube && {
    formatList=\$(\quvi -vq -F "\$url" | cut -d: -f1 | tr "|" "\n" | sort -t_ -k2 -r)
    for format in \$formatList
    do
      echo "=> format = \$format"
      containsmp3stream \$format "\$url" && {
        outputFilename=\$(\cclive -cf \$format "\$url" --exec "echo %f")
        getaudio "\$outputFilename" && \rm -v "\$outputFilename"
        break
      }
    done
    }
  done
}
ytgetmp4() {
  for tool in cclive quvi ffprobe
  do
    type \$tool >/dev/null || {
      echo "=> ERROR: <\$tool> is not installed." >&2
      return 1
    }
  done
  echo
  for url
  do
    echo "\$url" | grep -q youtube && {
    formatList=\$(\quvi -vq -F "\$url" | cut -d: -f1 | tr "|" "\n" | sort -t_ -k2 -r)
    for format in \$formatList
    do
      echo "=> format = \$format"
      containsmp4stream \$format "\$url" && {
        outputFilename=\$(\cclive -cf \$format "\$url" --exec "echo %f")
        test "\$outputFilename" && any2mp4 "\$outputFilename"
        break
      }
    done
    }
  done
}
ytgetogg() {
  for tool in cclive quvi ffprobe
  do
    type \$tool >/dev/null || {
      echo "=> ERROR: <\$tool> is not installed." >&2
      return 1
    }
  done
  echo
  for url
  do
    echo "\$url" | grep -q youtube && {
    formatList=\$(\quvi -vq -F "\$url" | cut -d: -f1 | tr "|" "\n" | sort -t_ -k2 -r)
    for format in \$formatList
    do
      echo "=> format = \$format"
      containsmp3stream \$format "\$url" && {
        outputFilename=\$(\cclive -cf \$format "\$url" --exec "echo %f")
        getaudio "\$outputFilename" && \rm -v "\$outputFilename"
        break
      }
    done
    }
  done
}
EOF
} | sudo tee -a /etc/bash.bashrc

test -f /usr/bin/any2mp4 || {
	sudo touch /usr/bin/any2mp4
	sudo chmod +x /usr/bin/any2mp4
	cat <<-EOF
#!/usr/bin/env sh

any2mp4Fonction() {
  local codeRet=0

  if type ffmpeg >/dev/null
  then
    videoConv=\$(which ffmpeg)
  else
    echo "=> ERROR: <ffmpeg> is not installed." >&2
    return 1
  fi

  for file
  do
    echo "=> file = \$file"
  #Si la video contient un flux h264, on remux les deux flux dans le conteneur MP4
    if \$videoConv -i "\$file" 2>&1 | egrep "Stream .*Video.*(h264)"
    then
      outPutFile="\${file%.???}.mp4"
    #Si le conteneur est du flash
      if \$videoConv -i "\$file" 2>&1 | egrep -q "^Input #[0-9], flv,"
      then
        freeSpace=\$(\df -Pk "\$file" | awk '/dev|tmpfs/{print int(\$4)}')
        fileSize=\$(\ls -l "\$file" | awk '{print int(\$5/1024)}')

        if [ \$freeSpace -lt \$fileSize ]
        then
             \mv -v "\$file" /tmp
             fileBaseName=\$(basename "\$file")
             \$videoConv -i "/tmp/\$fileBaseName" -f mp4 -vcodec copy -acodec copy "\$outPutFile" && \rm -v "/tmp/\$fileBaseName" || break
        else
             \$videoConv -i "\$file" -f mp4 -vcodec copy -acodec copy "\$outPutFile" || break
             \rm -v "\$file"
         fi
      else
        test "\$(echo "\$file" | awk -F. '{print\$NF}')" != mp4 && \mv -v "\$file" "\$outPutFile" ||echo "=> <\$file> is already a mp4 file."
      fi
    else
      echo "==> No h264 stream to copy was found." 2>&1
    fi
    echo
  done
  return
}

any2mp4Fonction "\$@"
EOF
} | sudo tee /usr/bin/any2mp4

typeset -A firefoxUserPreferenceOtions=([browser.download.manager.showWhenStarting]=false [browser.download.useDownloadDir]=false [privacy.clearOnShutdown.downloads]=false [privacy.clearOnShutdown.history]=false [privacy.sanitize.didShutdownSanitize]=true [privacy.sanitize.sanitizeOnShutdown]=true)

pgrep firefox >/dev/null || {
	echo "=> Mise a jour des parametres Firefox personalises ..."
	find $HOME/.mozilla/firefox -type f -name prefs.js | while read firefoxPreferenceFile
	do
		echo "==> firefoxPreferenceFile = $firefoxPreferenceFile"
		(
			for firefoxUserPref in "${!firefoxUserPreferenceOtions[@]}"
			do
  			grep -q $firefoxUserPref $firefoxPreferenceFile || echo "user_pref(\"$firefoxUserPref\", ${firefoxUserPreferenceOtions[$firefoxUserPref]});"
  			for i in 0 1 2 3 4 5 6
  			do
  				:
  #				grep -q print.tmp.printerfeatures.$printerName.paper.$i.name.*\"A4\" $firefoxPreferenceFile || echo "user_pref(\"print.tmp.printerfeatures.$printerName.paper.$i.name\", \"A4\");"
  			done
			done
		) | tee -a $firefoxPreferenceFile
	done
}

languagePackageList=""
languageList="de es pt zh-hans"
for language in $languageList
do
	languagePackageList="$languagePackageList language-pack-$language firefox-locale-$language"
done
dpkg -l | egrep -q "(language-pack-|firefox-locale-)(de|es|pt|zh-hans)" && echo "=> Suppressions des langues: $languageList ..." && $purgePackages $languagePackageList 

test -b $cdr_device && {
	type wodim >/dev/null 2>&1 || {
		echo "==> Installation du paquet <wodim> ..."
		$installPackages wodim
	}
	echo "=> Configuration du peripherique de gravure par defaut dans le fichier </etc/wodim.conf> ..."
	sudo touch /etc/wodim.conf
	sudo sed -i "s|^CDR_DEVICE=.*$|CDR_DEVICE=$cdr_device|" /etc/wodim.conf
}

echo "=> Configuration de l'imprimante reseau ..."
printerConfigFile=/etc/cups/printers.conf
sudo touch $printerConfigFile
sudo chmod +r $printerConfigFile
#PARTIE NESSITANT UNE CONNEXION RESEAU
gateWay=$(route -n | awk '/^0.0.0.0/{print$2}')
networkName=$(dig -x $gateWay +short 2>/dev/null | awk '{print$NF}' | cut -d. -f2-)
test "$networkName" || route | awk '/^default/{print$2}' | grep -q freebox && networkName=free
echo "=> networkName = $networkName"

case $networkName in
lan.|free) printerName=HP-LaserJet-1100
	echo "=> Ajout de l'imprimante $printerName ..."
	grep -q $printerName $printerConfigFile || {
	cat <<-EOF
	# Printer configuration file for CUPS v1.5.2
	# Written by cupsd
	# DO NOT EDIT THIS FILE WHEN CUPSD IS RUNNING
	<DefaultPrinter HP-LaserJet-1100>
	UUID urn:uuid:bf545b07-4eb0-3e94-4bbb-3cba69452769
	Info HP LaserJet 1100
	Location Au Salon
	MakeModel HP LaserJet 1100, hpcups 3.12.2
	DeviceURI socket://192.168.0.1:9100
	State Idle
	StateTime 1359059413
	Type 36876
	Accepting Yes
	Shared Yes
	JobSheets none none
	QuotaPeriod 0
	PageLimit 0
	KLimit 0
	OpPolicy default
	ErrorPolicy retry-job
	</Printer>
	EOF
} | sudo tee -a $printerConfigFile
;;
alti.lan.)	printerName=Canon-iR-C3080-3480-3580
	echo "=> Ajout de l'imprimante $printerName ..."
	grep -q $printerName $printerConfigFile || {
	cat <<-EOF
	<DefaultPrinter Canon-iR-C3080-3480-3580>
	UUID urn:uuid:23490c1e-3097-311c-7bd4-e64146edbf1f
	Info Canon iR C3080/3480/3580
	Location S1-COP-ET3
	MakeModel Canon iR C3080/3480/3580 UFR II ver.2.5
	DeviceURI socket://172.21.31.53:9100
	State Idle
	StateTime 1359465295
	Type 8402108
	Accepting Yes
	Shared Yes
	JobSheets none none
	QuotaPeriod 0
	PageLimit 0
	KLimit 0
	OpPolicy default
	ErrorPolicy retry-job
	Attribute marker-colors \#000000,#00FFFF,#FF00FF,#FFFF00,none
	Attribute marker-levels 97,98,84,60,-1
	Attribute marker-names C-EXV 21 Black Toner,C-EXV 21 Cyan Toner,C-EXV 21 Magenta Toner,C-EXV 21 Yellow Toner,Waste Toner
	Attribute marker-types toner,toner,toner,toner,wasteToner
	Attribute marker-change-time 1359465295
	</Printer>
	EOF
} | sudo tee -a $printerConfigFile
	test -x /usr/lib/cups/filter/pstoufr2cpca || sudo install -vp pstoufr2cpca /usr/lib/cups/filter/pstoufr2cpca
;;
*) printerName="" ;;
esac

test $printerName && {
	test -x /etc/cups/ppd/$printerName.ppd || sudo install -vp $printerName.ppd /etc/cups/ppd/
}

sudo service cups restart

if env | grep -q DISPLAY
then
	type numlockx >/dev/null 2>&1 || {
		echo "==> <numlockx> absent, installation de numlockx ..."
		$installPackages numlockx
	}
  echo "=> Allumage du pave numerique dans l'environement graphique courant ..." && numlockx on
fi

AddUbuntuRepository universe

env | grep -q LANGUAGE || {
	echo "=> Veuillez vous deconnecter et vous reconnecter avant de relancer le script <$0>."
	exit
}

echo "=> Voulez vous installer les plugins pour Firefox ? [O/n]"
firefoxPlugins="mozplugger gstreamer0.10-ffmpeg gstreamer0.10-fluendo-mp3"
read answer
if ! echo $answer | egrep -q "n|N"
then
	apt-cache show mozplugger >/dev/null 2>&1 || {
		echo "=> Mise a jour de la liste des paquets presents dans les depots logiciels, cela dure environ 60 secondes ..."
		$(which time) -p sudo apt-get update -qq || true
	}
	echo "=> Installation des paquets: $firefoxPlugins"
	$installPackages -y $firefoxPlugins
	$cleanPackages
fi

test $distribVersion -gt 10 && frenchPackageList="firefox-locale-fr language-pack-gnome-fr libreoffice-help-fr libreoffice-l10n-fr wfrench" || frenchPackageList="firefox-locale-fr language-pack-gnome-fr openoffice.org-help-fr openoffice.org-l10n-fr wfrench"
test $distribVersion -le 9 && frenchPackageList="language-pack-gnome-fr openoffice.org-help-fr openoffice.org-l10n-fr wfrench"

if ! dpkg -l $frenchPackageList 2>/dev/null | awk '/^ii/{printf "%s ", $2}END {print""}' | sort | grep -q "$frenchPackageList"
#if ! dpkg -l | grep -q libreoffice-l10n-fr
then
	echo "=> Voulez vous installer la langue francaise ? [O/n]"
	read answer
	if ! echo $answer | egrep -q "n|N"
	then
		echo "=> Installation des paquets: $frenchPackageList"
		$installPackages -y $frenchPackageList
		$cleanPackages
	fi
fi

echo "=> Suppression des paquets residuels ..."
sudo apt-get autoremove -q -y

mainPackageList="autoconf libtool lftp fdupes vim sysstat lvm2 curl libxml2 numlockx openssh-server gparted git-core dselect xmlstarlet wodim pdksh nmap"
echo "=> Installation des paquets: $mainPackageList"
$installPackages -y $mainPackageList | grep -v "is already the newest version."
$cleanPackages

if [ $distribRelease != 12.10 ]
then
	echo "=> Ajout du depot VMware pour les VMware Tools ..."
	grep -q packages.vmware.com /etc/apt/sources.list.d/vmware-tools-$distribCodeName.list 2>/dev/null || echo "deb http://packages.vmware.com/tools/esx/latest/ubuntu $distribCodeName main #VMware Tools" | sudo tee /etc/apt/sources.list.d/vmware-tools-$distribCodeName.list
	wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub -q -O- | sudo apt-key add -
fi

test $distribVersion -gt 10 && ppaRepositoriesList="ppa:stebbins/handbrake-releases ppa:mupdf/stable ppa:sparkers/ppa ppa:rvm/smplayer ppa:jon-severinsson/ffmpeg ppa:qmagneto/ppa ppa:cpug-devs/ppa ppa:nemh/gambas3 ppa:i-nex-development-team/stable ppa:indicator-multiload/stable-daily" || ppaRepositoriesList="ppa:stebbins/handbrake-releases ppa:sparkers/ppa ppa:rvm/smplayer ppa:jon-severinsson/ffmpeg ppa:qmagneto/ppa ppa:cpug-devs/ppa ppa:nemh/gambas3 ppa:i-nex-development-team/stable ppa:indicator-multiload/stable-daily ppa:gezakovacs/boost ppa:dnjl/build-multimedia ppa:ripps818/coreavc"
test $distribVersion -ge 10 && AddLaunchpadRepositories $ppaRepositoriesList

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

essentialUniversePackageList="gstreamer0.10-ffmpeg chm2pdf bashdb zsync p7zip-full gammu grub-pc grub-common html-xml-utils hwinfo pdftk libcdio-utils gstreamer-tools lsdvd lame vorbis-tools conky-all ccze mc cdrdao cdparanoia gdebi unrar-free cabextract keychain gpm mesa-utils vlock icedax mozplugger deborphan quvi lshw-gtk fsarchiver w3m ksh fping hping3"
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

test $distribVersion -gt 9 && universePackageList="transcode gpac ogmtools vobcopy gstreamer0.10-ffmpeg gstreamer0.10-fluendo-mp3 alacarte aptitude system-config-lvm dconf-tools chromium-browser libcdio-utils abcde bashburn cclive w3m-img" || universePackageList="alacarte aptitude system-config-lvm chromium-browser libcdio-utils abcde cclive w3m-img"
echo "=> Installation des paquets: $universePackageList ..."
$installPackages $universePackageList | grep -v "is already the newest version."
$cleanPackages

AddUbuntuRepository multiverse
sudo apt-get update -qq
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

notToBeErasedPackageList="pdksh,libav-tools,jockey-gtk,compiz-plugins-main-default,compiz-plugins-main,compiz-plugins-extra,compiz-fusion-plugins-main,compiz-fusion-plugins-extra"
test "$(deborphan -e $notToBeErasedPackageList)" && echo "=> Suppressions des paquets orphelins : <$(deborphan -e $notToBeErasedPackageList) ..." && $purgePackages $(deborphan -e $notToBeErasedPackageList)
echo "=> Fin."
