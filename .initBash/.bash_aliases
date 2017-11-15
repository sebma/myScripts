#!sh
wifiInterface="$(which iwconfig >/dev/null 2>&1 && iwconfig 2>/dev/null | awk '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { print $2 } else { print $1 } }' || ( which iw >/dev/null 2>&1 && iw dev | awk '/Interface/{lastInterface=$NF}END{print lastInterface}') )"
#alias processUsage="printf ' RSS\t       %%MEM %%CPU  COMMAND\n';\ps -e -o rssize,pmem,pcpu,args | sort -nr | cut -c-156 | head -500 | awk '{printf \"%9.3lf MiB %4.1f%% %4.1f%% %s\n\", \$1/1024, \$2,\$3,\$4}' | head"
#alias ssh="\ssh -A -Y -C"
#sdiff -v 2>/dev/null | grep -qw GNU && alias sdiff='$(which sdiff) -Ww $(tput cols 2>/dev/null)' || alias sdiff='$(which sdiff) -w $(tput cols 2>/dev/null)'
alias ....="cd ../../.."
alias ...="cd ../.."
alias ..="cd .."
alias acp='\advcp -gpuv'
alias amv='\advmv -gvi'
type arch >/dev/null 2>&1 || alias arch="uname -m"
alias audioInfo="which mplayer >/dev/null 2>&1 && \mplayer -identify -vo null -ao null -frames 0"
alias bc="\bc -l"
alias brewUpdate="time \brew update -v"
alias bsu='chmod +r $XAUTHORITY;cd $BEA_HOME/utils/bsu; ./bsu.sh'
alias burnaudiocd='\burnclone'
alias burncdrw='\cdrecord -v -dao driveropts=burnfree fs=14M speed=12 gracetime=10 -eject'
alias burnclone='\cdrecord -v -clone -raw driveropts=burnfree fs=14M speed=16 gracetime=10 -eject -overburn'
alias burniso='\cdrecord -v -dao driveropts=burnfree fs=14M speed=24 gracetime=10 -eject -overburn'
alias cclive="\cclive -c"
which ccze >/dev/null 2>&1 && alias ccze="\ccze -A" && alias dmesg="\ccze -A < /var/log/dmesg"
alias cdda_info="\icedax -gHJq -vtitles"
alias cdrdao='\df | grep -q $CDR_DEVICE && umount -vv $CDR_DEVICE ; \cdrdao'
alias cget="\curl -O"
alias checkMyPrinterConnection="\ping -c2 192.168.1.1"
alias checkcer="\openssl x509 -noout -inform PEM -in"
alias checkcertif="\openssl verify -verbose"
alias checkcrt="\openssl x509 -noout -inform PEM -in"
alias checkder="\openssl x509 -noout -inform DER -in"
alias clearXFCESessions="\rm -fv ~/.cache/sessions/xf*"
alias clearurlclassifier3="$(which find) . -type f -name urlclassifier3.sqlite -exec rm -vf {} \;"
alias closecd='\eject -t $CDR_DEVICE'
alias connect2MyHiddenWifi="\time nmcli con up id SebWlanFree && wanip"
alias connect2SSID="time nmcli con up id"
alias copy2Clipboard="\xclip -i -selection clipboard"
alias cp2SDCard="rsync --size-only"
alias cp2ftpfs="\rsync -uth --progress --inplace --size-only"
alias cpanRepair="$(which cpan) -f -i Term::ReadLine::Gnu"
alias cpuUsage="which mpstat >/dev/null && mpstat 1 1 | awk 'END{print 100-\$NF\"%\"}'"
which curl >/dev/null 2>&1 && alias curl="\curl -L"
alias curlResposeCode="\curl -sw "%{http_code}" -o /dev/null"
alias dbus-halt='\dbus-send --system --print-reply --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop'
alias dbus-hibernate='\dbus-send --system --print-reply --dest="org.freedesktop.UPower" /org/freedesktop/UPower org.freedesktop.UPower.Hibernate'
alias dbus-logout-force-kde='\qdbus org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.logout 0 0 0'
alias dbus-logout-kde='\qdbus org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.logout -1 -1 -1'
alias dbus-reboot='\dbus-send --system --print-reply --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Restart'
alias dbus-suspend='\dbus-send --system --print-reply --dest="org.freedesktop.UPower" /org/freedesktop/UPower org.freedesktop.UPower.Suspend'
alias deborphan="\deborphan | sort"
alias dig="\dig +search +short"
alias diskinfo='\cdrdao disk-info'
alias doc2pdf=" \lowriter --headless --convert-to pdf"
alias docx2pdf="\lowriter --headless --convert-to pdf"
alias dos2unix='\perl -pi -e "s/\r//g"'
alias doublons='\fdupes -rnASd'
alias driveinfo='\cdrecord -prcap'
alias du="LANG=C \du -h"
alias ejectcd='\eject $CDR_DEVICE'
alias eman="\man -L en"
alias enman="LANG=en_US \man"
alias erasecd='\cdrecord -v speed=12 blank=fast gracetime=10 -eject'
alias erasewholecd='\cdrecord -v speed=12 blank=all gracetime=10 -eject'
alias errors="\egrep -iC2 'error|erreur|java.*exception'"
alias ffmpeg="time \ffmpeg -hide_banner"
alias ffplay="\ffplay -hide_banner"
alias findFunctions="grep -P '(^| )\w+\(\)|\bfunction\b'"
#alias findLoops='$(which find) . -follow -printf "" 2>&1 | egrep -w "loop|denied"'
alias findSpecialFiles="$(which find) . -xdev '(' -type b -o -type c -o -type p -o -type s ')' -a -ls"
alias findbin='$(which find) $(echo $PATH | tr : "\n" | \egrep "/(s?bin|shl|py|rb|pl)") /system/{bin,xbin} 2>/dev/null | egrep'
alias free="\free -m"
alias frman="LANG=fr_FR.UTF-8 \man"
alias fuser="\fuser -v"
alias fuserumount="\fusermount -u"
alias gateWay="\route -n | awk '/^(0.0.0.0|default)/{print\$2}'"
alias gdmlogout="\gnome-session-quit --force"
alias getPip="\wget -qO- https://bootstrap.pypa.io/get-pip.py | python"
alias getUuid="\blkid -o value -s UUID"
alias gitLocalUndelete="\git ls-files -d | grep . && \git ls-files -d | \xargs git checkout-index"
alias gitStatus="\git status -bs -uno"
alias gitUpdate='\grep -w "^[[:blank:]]url" ./.git/config;\git pull'
alias gitURL='\grep -w "^[[:blank:]]url" ./.git/config'
alias grepInHome="time \grep --exclude-dir=Audios --exclude-dir=Music --exclude-dir=Podcasts --exclude-dir=Videos --exclude-dir=Karambiri --exclude-dir=iso --exclude-dir=Downloads --exclude-dir=Documents --exclude-dir=src --exclude-dir=Pictures --exclude-dir=.thunderbird --exclude-dir=deb --exclude-dir=apks --exclude-dir=.mozilla --exclude-dir=.PlayOnLinux --exclude-dir=PlayOnLinux\'s\ virtual\ drives --exclude-dir=.cache --exclude-dir=Sauvegarde_MB525 --exclude-dir=A_Master_RES --exclude-dir=SailFishSDK --exclude=.*history"
alias gunzip="\gunzip -Nv"
alias gzcat="\gunzip -c"
alias gzgrep="\zgrep ."
alias gzip="\gzip -Nv"
alias halt="\halt && exit"
alias hexdump="\od -ctx1"
alias hexdump="which hexdump >/dev/null && hexdump || \od -ctx1"
alias html2xml="\xmllint --html --format --recover --xmlout"
alias integer="typeset -i"
alias inxi="\inxi -c21"
alias inxiSummary="\inxi -c21 -Admi -v4"
alias jpeg2pdf="\convert -gravity center"
alias jpeg2pdfA4="\convert -set density '%[fx:w/8.27]' -gravity center"
alias jpg2pdf=jpeg2pdf
alias jpg2pdfA4=jpeg2pdfA4
alias pic2pdf=jpeg2pdf
alias pic2pdfA4=jpeg2pdfA4
alias img2pdf=jpeg2pdf
alias img2pdfA4=jpeg2pdfA4
alias killall2="\killall -v"
alias kshVersion="type ksh >/dev/null && strings $(which ksh) | grep Version | tail -2"
alias lanip="\ip addr show | awk '/inet /{print\$2}' | egrep -v '127.0.0.[0-9]|192.168.122.[0-9]'"
alias lastfiles='$(which find) . -xdev -type f -mmin -2'
alias less="\less -r"
alias ll="ls -lF"
alias lla="ll -a"
alias llah="ll -ah"
alias lld="ll -d"
alias llh="ll -h"
alias llha="ll -ha"
alias loadsshkeys='eval $(keychain --eval --agents ssh)'
alias lprColor="\lpr -P $(lpstat -a 2>/dev/null | awk '/[Cc](olor|ouleur)/{print$1;exit}')"
alias a2psColor="\a2ps -P $(lpstat -a 2>/dev/null | awk '/[Cc](olor|ouleur)/{print$1;exit}')"
alias lpr2ppsheet="\lpr -o number-up=2"
alias lpq="\lpq -a +2"
alias ls="ls -F"
#alias lsb_release="\lsb_release -idrc"
which lsb_release >/dev/null 2>&1 && alias lsb_release="\lsb_release -s"
alias lsdvd="\lsdvd -avcs"
alias lshw="\lshw -numeric -sanitize"
alias lspci="\lspci -nn"
alias lxterm="\lxterm -sb -fn 9x15"
alias manen=enman
alias manfr=frman
alias mountfreebox="mount | \grep -wq freebox-server || curlftpfs 'freebox@freebox-server.local/Disque dur' /mnt/freebox/ ; mount | \grep -w freebox-server"
alias mountfreeboxanna="mount | \grep -wq freeboxanna || curlftpfs 'freebox@78.201.68.5/Disque dur' /freeboxanna/ ; mount | \grep -w freeboxanna"
alias mpvlive='mpv --no-resume-playback'
alias mpvlocal='mpv --no-ytdl'
alias mpvplaylist='mpv --playlist'
alias mutt="LANG=C.UTF-8 \mutt"
alias muttDebug="LANG=C.UTF-8 \mutt -nd5"
alias mv='\mv -vi'
alias myCity="time curl ipinfo.io/city"
alias myCountry="time curl ipinfo.io/country"
alias myIP="time curl ipinfo.io/ip"
alias mysed="\perl -p"
alias nautilus="\nautilus --no-desktop"
alias no='yes n'
alias od="\od -ctx1"
alias odt2pdf="\lowriter --headless --convert-to pdf"
alias page="\head -50"
alias pcmanfm="\pcmanfm --no-desktop"
alias perlInterpreter="\perl -de ''"
alias pgrep="\pgrep -lf"
alias phpInterpreter="\php -a"
groups 2>/dev/null | egrep -wq "admin|sudo" && alias pipInstall=" sudo -H easy_install pip"  || alias pipInstall="easy_install --user pip"
groups 2>/dev/null | egrep -wq "admin|sudo" && alias pip3Install="sudo -H easy_install3 pip" || alias pip3Install="easy_install3 --user pip"
alias pipUpdate="pip install -U pip"
alias ports="lsof -ni -P | grep LISTEN"
alias tcpPorts="\netstat -ntl"
alias prettyjson='\python -m json.tool'
alias ps="\ps -f"
alias psu='\ps -fu $USER'
alias putty='\putty -geometry 157x53 -l $USER -t -A -C -X'
alias qrdecode="\zbarimg -q --raw"
alias rcp="\rsync -uth -P"
alias reboot="\reboot && exit"
alias recode="\recode -v"
alias regrep="which regrep >/dev/null || egrep -Ir"
alias rename="\prename -v"
alias repeat="\watch -n1"
alias restartWifi="nmcli nm wifi off;nmcli nm wifi on;sleep 10;wanip"
alias restart_conky="\pgrep conky && \killall -SIGHUP conky || conky -d"
alias conky_restart=restart_conky
alias restore_my_stty="\stty erase ^?"
alias rgrep="$(which rgrep >/dev/null 2>&1) && \rgrep || grep -Ir"
alias rm="\rm -i"
alias rpml="\rpm --root ~/local -Uvh"
alias rpmt="\rpm --test"
alias rsync2SDCard="rsync --size-only"
alias rsyncMove="rsync --remove-source-files"
alias scp_unix='time \rsync -h --progress --rsync-path=$HOME/gnu/bin/rsync -ut'
alias sdiff='\sdiff -w $COLUMNS'
alias sortip="\sort -nt. -k1,1 -k2,2 -k3,3 -k4,4"
alias sudo="\sudo "
alias sum="\awk '{sum+=\$1}END{print sum}'"
alias swapUsage="\free -m | awk '/^Swap/{print 100*\$3/\$2}'"
alias terminfo='echo "=> C est un terminal $(tput cols 2>/dev/null)x$(tput lines 2>/dev/null)."'
alias testLiveIso="\kvm -m 1G -cdrom"
alias timestamp='\date +"%Y%m%d_%HH%M"'
alias today="$(which find) . -type f -ctime -1"
alias topd10="\du -cxsm */ .??*/ 2>/dev/null | sort -nr | head -10"
alias topd5="\du  -cxsm */ .??*/ 2>/dev/null | sort -nr | head -5"
alias topd="\du   -cxsm */ .??*/ 2>/dev/null | sort -nr | head -n"
alias topdlines='\du   -cxsm */ .??*/ 2>/dev/null | sort -nr | head -$(($LINES-2))'
alias ulogerrors="egrep -iB4 -A1 'error|erreur|Err: [^0]'"
#alias ulogtodayerrors="egrep -iB4 -A1 'error|erreur|Err: [^0]' $ulog"
alias umask="\umask -S"
alias umount="\umount -vv"
alias uncompress="\uncompress -v"
alias uncpio="\cpio -idcmv <"
alias unix2dos='\perl -pi -e "s/\n/\r\n/g"'
alias unjar="\unzip"
alias unjar="$(which unjar) 2>/dev/null || \unzip"
alias untar="\tar -xvf"
alias untar="$(which untar) 2>/dev/null || \tar -xvf"
alias updateBrew="time \brew update -v"
alias updateGIT="\git pull"
alias updatePip="pip install -U pip"
alias updateThumbnail="\exiftran -gi"
alias updateYoutube-dl="pip install -U youtube-dl"
alias updatedb='updatedb -l 0 -o ~/.local/lib/mlocate/mlocate.db --prunefs "rpc_pipefs afs binfmt_misc proc smbfs iso9660 ncpfs coda devpts ftpfs devfs mfs shfs sysfs cifs lustre tmpfs usbfs udf fuse.glusterfs fuse.sshfs curlftpfs"'
alias uuidGet="\blkid -o value -s UUID"
#alias vict2c="vim +'setf xml' $LOGDIR/ct2c.log"
alias vimatlab="vim +'setf matlab'"
alias vihistory='\vim ~/.bash_history'
alias vioctave=vimatlab
alias view='vim -R'
alias viewcer="\openssl x509 -noout -text -inform DER -subject -issuer -dates -purpose -nameopt multiline -in"
alias viewpem="\openssl x509 -noout -text -inform PEM -subject -issuer -dates -purpose -nameopt multiline -in"
alias viewcrt="viewcer"
alias viewcsr="\openssl req -noout -text -inform PEM -in"
alias viewder="\openssl x509 -noout -text -inform DER -in"
alias vlclocal='DISPLAY=:0 vlc'
alias wanip='time \curl -A "" ipinfo.io/ip || time \wget -qU "" -O- ipinfo.io/ip'
alias wanipOLD='time \dig +short myip.opendns.com @resolver1.opendns.com'
alias wavemon="xterm -e wavemon &"
alias wget="\wget -c --content-disposition"
alias wifiList="which nmcli >/dev/null && nmcli dev wifi list || iw dev $wifiInterface scan || iwlist $wifiInterface scan"
alias wifiRestart=restartWifi
alias xargs="\xargs -ri"
alias xclock="\xclock -digital -update 1"
alias xfree="\xterm -geometry 73x5 -e watch -n2 free -om &"
alias xmlsh="\xmllint --shell"
alias xpath="\xmllint --xpath"
alias xprop='\xprop WM_CLASS _NET_WM_PID WM_ICON_NAME'
alias xterm="\xterm -bc -fn 9x15 -geometry 144x40 -sb"
alias xwinInfo="\ps -fp \$(\xprop _NET_WM_PID | awk -F'=' '/_NET_WM_PID/{print\$NF}')"
alias youtube-dlUpdate="pip install -U youtube-dl"
alias ytGetAudio="\youtube-dl -f 249/250/251/171/m4a"
alias ytdl="\youtube-dl"
alias ytdlUpdate="pip install -U youtube-dl"
alias zegrep="which zegrep >/dev/null || zgrep -E"
egrep --help 2>&1 | \grep -qw "\--color" && alias egrep="egrep --color"
grep  --help 2>&1 | \grep -qw "\--color" && alias grep="grep --color"
test $TNS_ADMIN && alias mysqlplus='echo "=> Connecting to database <$ORACLE_SID> as <$USER> ...";sqlplus $USER' || alias sqlplus="echo ERROR: Variable TNS_ADMIN is not defined. >&2;"
uname -s | grep -q AIX && alias stat="istat"
which vim >/dev/null && alias vim="LANG=$(locale -a | egrep -i '(fr_fr|en_us|en_uk).*utf' | sort -r | head -1) \vim" && alias vi=vim
