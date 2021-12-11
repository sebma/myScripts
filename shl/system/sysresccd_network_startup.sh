#!/usr/bin/env bash

[ $(id -u) -ne  0 ] && {
	echo "=> You must be root to run this script" 1>&2
	exit 1
}

echo "=> Running $0..."

#Activation du clavier francais sur la console et sur "XWindow"
loadkeys fr-latin9
echo XKEYBOARD=fr > /etc/sysconfig/keyboard


#Activation du "NumLock" sur tous les "tty" de la console
#et desactivation du beep sur la console et sur "XWindow"
INITTY=/dev/tty[1-8]
ListHardWareCmd="command lshw || command lshal"
$ListHardWareCmd | egrep -qi "notebook|laptop" || {
	for tty in $INITTY; do
		setleds -D +num < $tty
	done
}

for tty in $INITTY; do
	setterm -blength 0 < $tty
	#setterm -msglevel 4 < $tty #Cela positionne le niveau de debug des messages kernel au niveau 4
done
#xset b off

#Activation du "NumLock" sur "XWindow"
grep -q "KEYPAD" /usr/share/X11/xkb/types/basic || {
	echo 'type "KEYPAD" {'
	echo "modifers = Shift+Numlock;"
	echo "map[None] = Level1;"
	echo "map[Shift] = Level2;"
	echo "map[NumLock] = Level2;"
	echo "map[Shift+Numlock] = Level1;"
	echo 'Level_name[Level1] = "base";'
	echo 'Level_name[level2] = "Number";'
	echo '}'
} >> /usr/share/X11/xkb/types/basic

#Configuration reseau de la premiere interface Ethernet
IFace=$(ifconfig -a | grep "eth[0-9].*Ethernet" | head -1 | cut -d' ' -f1)
[ -z "$IFace" ] && {
	echo "=> Error: Interface not found !" 1>&2 
	exit 2
}

#@IP par default si elle n'est passee en parametre
DefaultIP=192.170.0.250

[ $# -gt 1 ] && {
	echo "=> Usage: <$0> @IP" 1>&2
	exit 3
}

[ -n "$1" ] && IP=$1 || IP=$DefaultIP
Gateway="$(echo $IP | cut -d. -f1-3).1"

ifconfig $IFace | egrep -q "^ {10}UP " || ifconfig $IFace up
ifconfig $IFace | grep -q "$IP" || ifconfig $IFace $IP

route -n | grep -q $Gateway || route add default gw $Gateway
sed -i "s;\($HOME\):.*bin/.*sh;\1:$(which zsh);" /etc/passwd
sed -i "s/.*X11Forwarding.*no/X11Forwarding yes/" /etc/ssh/sshd_config && /etc/init.d/sshd restart

for vim_options in ai "ts=4" "syn=ON"
do
	grep -q "set $vim_options" $HOME/.vimrc 2>/dev/null || echo set $vim_options >> $HOME/.vimrc
done

[ ! -e $HOME/.screenrc ] && {
	for i in $(seq 6)
	do
		echo screen
		#echo title \"Remote console $SSH_TTY\" | sed "s/[0-9]/$i/"
		echo title \"Remote console number $i\"
	done > $HOME/.screenrc
	echo select 0 >> $HOME/.screenrc
}

CurrentShellDotProfile=".$(basename $(echo $SHELL))_profile"
[ ! -e $HOME/.profile ] && [ -e "$CurrentShellDotProfile" ] && cd $HOME && ln -s "$CurrentShellDotProfile" .profile && cd -

grep -q screen $HOME/.profile 2>/dev/null || echo '[ -n "$SSH_TTY" ] && screen' >> $HOME/.profile
tty | grep -q "/dev/tty[1-9]" && passwd

exit 0

