# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
		debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#		PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#		;;
#*)
#		;;
#esac

# enable bash completion in interactive shells
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#		. /etc/bash_completion
#fi

# sudo hint
if [ ! -e "$HOME/.sudo_as_admin_successful" ]; then
		case " $(groups) " in *\ admin\ *)
		if [ -x /usr/bin/sudo ]; then
	cat <<-EOF
	To run a command as administrator (user "root"), use "sudo <command>".
	See "man sudo_root" for details.
	
	EOF
		fi
		esac
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found ]; then
	function command_not_found_handle {
					# check because c-n-f could've been removed in the meantime
								if [ -x /usr/lib/command-not-found ]; then
			 /usr/bin/python /usr/lib/command-not-found -- $1
									 return $?
								elif [ -x /usr/share/command-not-found ]; then
			 /usr/bin/python /usr/share/command-not-found -- $1
									 return $?
		else
			 return 127
		fi
	}
fi

#DEFINITIONS DES FONCTIONS
build_in_HOME() {
	test -s configure || {
	 test -x bootstrap.sh && time ./bootstrap.sh
	 test -x autogen.sh && time ./autogen.sh --prefix=$HOME/gnu $@
	}
	test -s Makefile || time ./configure --prefix=$HOME/gnu $@
	test -s Makefile && time make && make install
}
build_in_usr() {
	test -s configure || {
	 test -x bootstrap.sh && time ./bootstrap.sh
	 test -x autogen.sh && time ./autogen.sh --prefix=/usr $@
	}
	test -s Makefile || time ./configure --prefix=/usr $@
	test -s Makefile && time make && sudo make install
}

convertPuttyPubKeys () {
	\umask 077
	test -d $HOME/.ssh && chmod 700 $HOME/.ssh || mkdir $HOME/.ssh
	for puTTYPubKey
	do
		ssh-keygen -i -f $puTTYPubKey >> $HOME/.ssh/authorized_keys
	done
}

#alias ssh="command ssh -qAY"
ssh () { test $1 && server=$(echo $1 | cut -d@ -f2) && $(which bash) -c ": < /dev/tcp/$server/ssh" && $(which ssh) -qAY $@; }

topf5() { find . -xdev -type f -size +10M $@ -printf "%M %n %u %g %k %AY-%Am-%Ad %AX %p\n" 2>/dev/null | sort -nk5 | tail -5|awk '{size=$5/1024;sub($5,size"M");print}'|column -t;}
topf10(){ find . -xdev -type f -size +10M $@ -printf "%M %n %u %g %k %AY-%Am-%Ad %AX %p\n" 2>/dev/null | sort -nk5 | tail |	awk '{size=$5/1024;sub($5,size"M");print}'|column -t;}
topf () {
		nbLines=$1
		test $nbLines && {
			shift
			find . -xdev -type f -size +10M $@ -printf "%M %n %u %g %k %AY-%Am-%Ad %AX %p\n" 2>/dev/null | sort -nk5 | tail -n $nbLines | awk '{size=$5/1024;sub($5,size"M");print}' | column -t
		}
	}

nameof() {
	for user
	do
		awk -F":|," /$user/'{print$5}' /etc/passwd
	done
}

httpserver() {
	mkdir -p ~/log
	fqdn=$(host $(hostname) | awk '/address/{print$1}')
	test $1 && port=$1 || port=1234
	test $port -lt 1024 && {
		echo "=> ERROR: Only root can bind to a tcp port lower than 1024." >&2
		return 1
	}

	\ps -fu $USER | grep -v grep | grep -q SimpleHTTPServer && echo "=> SimpleHTTPServer is already running on http://$fqdn:$(\ps -fu $USER | grep -v awk | awk '/SimpleHTTPServer/{print$NF}')/" || {
		logfilePrefix=SimpleHTTPServer_$(date +%Y%m%d)
		nohup python -m SimpleHTTPServer $port >~/log/${logfilePrefix}.log 2>&1 &
		test $? = 0 && {
			echo "=> SimpleHTTPServer started on http://$fqdn:$port/"
			echo "=> logFile = ~/log/${logfilePrefix}.log"
		}
	}
}

scp() {
	#scpCommand="command rsync -pPt -uv --rsh="$(type -P ssh) -qt"
	scpCommand="command rsync -pPt -v"
	$scpCommand -e "command ssh -qt" $@
	test $? = 127 && {
		$scpCommand -e "$(which ssh) -qt" --rsync-path=/usr/local/bin/rsync $@ || $(which scp) -p $@
	}
}

deployCEAix() {
	test $USER = x064304 && CashEuropeAixServerList="deur01 heur01 heur02" || CashEuropeAixServerList="deur01 heur01 heur02 peur01 peur02"
	for file
	do
		echo "=> Deploying <$file> on <$CashEuropeAixServerList> ..."
		for server in $CashEuropeAixServerList
		do
			echo
			echo "==> Copying $file on $server: ..."
			scp $1 $server:
		done
	done
	echo
}

deployCELinux() {
	test $USER = x064304 && CashEuropeLinuxServerList="deurlx01 deurlx02 deurlx03 heurlx01 heurlx02 heurlx03 heurlx04" || CashEuropeLinuxServerList="deurlx01 deurlx02 deurlx03 heurlx01 heurlx02 heurlx03 heurlx04 peurlx01 peurlx02 peurlx03 peurlx04"
	for file
	do
		echo "=> Deploying <$file> on <$CashEuropeLinuxServerList> ..."
		for server in $CashEuropeLinuxServerList
		do
			echo
			echo "==> Copying $file on $server: ..."
			scp $1 $server:
		done
	done
	echo
}

deployCE() {
	test $USER = x064304 && CashEuropeLinuxServerList="deurlx01 deurlx02 deurlx03 heurlx01 heurlx02 heurlx03 heurlx04" || CashEuropeLinuxServerList="deurlx01 deurlx02 deurlx03 heurlx01 heurlx02 heurlx03 heurlx04 peurlx01 peurlx02 peurlx03 peurlx04"
	test $USER = x064304 && CashEuropeAixServerList="deur01 heur01 heur02" || CashEuropeAixServerList="deur01 heur01 heur02 peur01 peur02"
	for file
	do
		echo "=> Deploying <$file> on <$CashEuropeLinuxServerList $CashEuropeAixServerList> ..."
		for server in $CashEuropeLinuxServerList $CashEuropeAixServerList
		do
			echo
			echo "==> Copying $file on $server: ..."
			scp $1 $server:
		done
	done
	echo
}

type finger >/dev/null 2>&1 || finger () {
	test $1 && argList=$* || argList=$(who | awk '{print$1}')
	for user in $argList
	do
		awk -F":|," /$user/'{print$1":"$5}' /etc/passwd
	done
}

lsgroup() {
	for group
	do
		awk -F: /^$group/'{gsub(",","\n");print$4}' /etc/group | while read user
		do
			awk -F":|," /$user/'{print$1":\""$5"\""}' /etc/passwd
		done
	done
}

isOwner () {
	test $# = 1 && test -O "$1" && true || false
}

getIP() { ip -4 addr show $@ | awk '/inet/{print$2}' ; }

#DEFINITIONS DES ALIAS
type sudo >/dev/null 2>&1 && alias sudo="\sudo -E"
alias dig="\dig +search +short"
uname -s | grep -q AIX && alias stat=istat
alias umask="\umask -S"
alias psu="\pgrep -lfu \$USER"
alias pgrep="\pgrep -lf"
#alias ll="ls -lF"
alias ll="LANG=C ls -lF --color=tty --time-style=+'%Y-%m-%d %H:%M:%S'"
alias cp="\cp -uv"
sdiff -v 2>/dev/null | grep -qw GNU && alias sdiff='\sdiff -Ww $(tput cols)' || alias sdiff='\sdiff -w $(tput cols)'
alias mv="\mv -v"
alias rm="\rm -iv"
alias df="\df -h"
alias hexdump="\od -ctx1"
alias od="\od -ctx1"
alias less="\less -r"
alias topd10="\du -xsm */ .??*/ | sort -n | tail -10"
alias topd5="\du -xsm */ .??*/ | sort -n | tail -5"
alias topd="\du -xsm */ .??*/ | sort -n | tail -n"
alias dos2unix='\perl -pi -e "s/\r//g"'
alias unix2dos='\perl -pi -e "s/\n/\r\n/g"'
alias lastfiles="\find . -type f -cmin -5 -ls"
alias doublons='\fdupes -rd .'
alias du="LANG=C \du -h"
alias cdda_info="\icedax -gHJq -vtitles"
alias cdrdao='\df | grep -q \$CDR_DEVICE && umount -vv \$CDR_DEVICE ; \cdrdao'
alias checkcertif="\openssl verify -verbose"
alias checkcer="\openssl x509 -noout -inform PEM -in"
alias checkcrt="\openssl x509 -noout -inform PEM -in"
alias checkder="\openssl x509 -noout -inform DER -in"

