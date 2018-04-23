# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
stty erase ^?

if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH:$HOME/shl"
fi

PATH=$PATH:/usr/lib/ssl/misc
#####################################################################
interpreter=`ps -o pid,comm | awk /$$/'{print $2}'`
EDITOR=vim

LANG=C
#ln -s .bash_profile .profile
#sed -i "s;PATH:;PATH:/sbin:/usr/sbin:;" .profile
normal="\e[0m"
bright="\e[1m"

red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
magenta="\e[35m"
cyan="\e[36m"
grey="\e[37m"

newline="$(printf '\n\a')"
#HostName=$(host -n $(hostname) | awk 'NR==1{print$1}')
HostName=$(host -n $(hostname) | cut -d. -f1-2)
uname -s | grep -q Linux && distribName=$(awk 'NR==1{print$1"-"$2}' /etc/issue): || distribName=$(uname -s):
if [ $interpreter = bash ]
then
  export PS1=$(printf "PPID=$PPID:$green$distribName$LOGNAME@$bright$blue$HostName:$green\w/$newline\$ $normal\n")
else
  export PS1=$(printf "PPID=$PPID:$green$distribName$LOGNAME@$bright$blue$HostName:$green\$PWD/$newline\$ $normal\n")
fi

export BOLD=$(tput smso)
export BRIGHT=$(tput bold)
export SURL=$(tput smul)
export NORMAL=$(tput sgr0)

echo "=> MIT-MAGIC-COOKIE-1:"
xauth list | grep :$(echo $DISPLAY | awk -F '\\.|:' '{print$2}')
echo
ps -fu $USER
echo
echo "=> Liste des users connectes :"
finger
echo

echo "=> Searching for full filesystems on our servers ..."
linuxServers="pingoin01 pingoin02"
for linux in $linuxServers
do
  echo "=> Linux server = $linux"
  nc -vz $linux ssh 2>&1 | grep -q succeeded && ssh $linux df 2>/dev/null  | awk /%/'{print$(NF-1)" "$NF}' | grep -v cdrom | egrep --color "100%"
  echo
done

aixServers="toto01 toto02"
for aix in $aixServers
do
  echo "=> AIX server = $aix"
  nc -vz $aix ssh 2>&1 | grep -q succeeded && ssh $aix "df -P" 2>/dev/null | awk /%/'{print$(NF-1)" "$NF}' | grep -v cdrom | egrep --color "100%"
  echo
done

export ENV=$HOME/.shrc
