echo "=> Debut d'execution du .profile"
set -o nolog
OSType=$(uname -s)
export APP=$(hostname | tr [:upper:] [:lower:] | cut -c2-4)
test -z "$CLEARCASE_ROOT" && test $(id -gn) = me$APP && clear
echo "=> C'est un terminal $(tput cols)x$(tput lines)."
exportCommand=export
addpath() {
  test ! -d "$1" && return
  echo $PATH | grep -wq "$1" || $exportCommand PATH=$PATH:$1
}

addmanpath() {
  test ! -d "$1" && return
  echo $MANPATH | grep -wq "$1" || $exportCommand MANPATH=$MANPATH:$1
}

export LANG=C
echo "=> Recherche des produits Oracle, Clearcase, Tuxedo, Apache et MQ puis ajout des chemins dans le PATH ..."
sqlplusPATH=$(which sqlplus 2>/dev/null || find /usr/ /produits/ /opt/ -name sqlplus -type f 2>/dev/null | head -1)
test $sqlplusPATH && {
  ORACLE_BIN=$(dirname $sqlplusPATH)
  export ORACLE_HOME=$(dirname $ORACLE_BIN)
}

cleartoolPATH=$(which cleartool 2>/dev/null || find /usr/ /produits/ /opt/ -name cleartool -type f 2>/dev/null | head -1)
test $cleartoolPATH && {
  CLEARCASE_BIN=$(dirname $cleartoolPATH)
  export CLEARCASE=$(dirname $CLEARCASE_BIN)
}

tmadminPATH=$(which tmadmin 2>/dev/null || find /usr/ /produits/ /opt/ -name tmadmin -type f  2>/dev/null| head -1)
test $tmadminPATH && {
  TUX_BIN=$(dirname $tmadminPATH)
  export TUXDIR=$(dirname $TUX_BIN)
}

weblogicPATH=$(which commEnv.sh 2>/dev/null || find /usr/ /produits/ /opt/ -name commEnv.sh -type f 2>/dev/null | head -1)
test $weblogicPATH && {
  WL_BIN=$(dirname $weblogicPATH)
  export WL_HOME=$(cd $WL_BIN/../..;pwd)
  export WLS_HOME=$WL_HOME/server
}

apachectlPATH=$(which apachectl 2>/dev/null || find /usr/ /produits/ /opt/ -name apachectl -type f 2>/dev/null | head -1)
test $apachectlPATH && {
  apacheBin=$(dirname $apachectlPATH)
  export apacheHome=$(dirname $apacheBin)
}

ccPATH=$(which cc 2>/dev/null || find /usr/ -name cc -type f 2>/dev/null | head -1)
test $ccPATH && {
   CC_BIN=$(dirname $ccPATH)
   CC_HOME=$(dirname $CC_BIN)
   export CC=$ccPATH
}

runmqscPATH=$(which runmqsc 2>/dev/null || find /usr/ /produits/ /opt/ -name runmqsc -type f 2>/dev/null | head -1)
test $runmqscPATH && {
  MQ_BIN=$(dirname $runmqscPATH)
  export MQ_HOME=$(dirname $MQ_BIN)
}

amqsreqPATH=$(which amqsreq 2>/dev/null || find /usr/ /produits/ /opt/ -name amqsreq -type f 2>/dev/null | head -1)
test $amqsreqPATH && {
  MQSAMPLE_BIN=$(dirname $amqsreqPATH)
  export MQSAMPLE_HOME=$(dirname $MQSAMPLE_BIN)
}

sslCAToolPATH=$(which CA.pl 2>/dev/null || find /usr/ /var/ /produits/ /opt/ -name CA.pl -type f 2>/dev/null | head -1)
test $sslCAToolPATH && {
  CATool_Bin=$(dirname $sslCAToolPATH)
  export CATool_HOME=$(dirname $CATool_Bin)
}

PATH=$HOME/gnu/bin:$HOME/bin:$PATH
case $OSType in
  AIX)
    pathsList="/sbin /usr/sbin /usr/ucb $CC_BIN $MQSAMPLE_BIN /opt/opsware/agent/bin $CLEARCASE_BIN $ORACLE_BIN $apacheBin $CATool_Bin"
    manPathsList="$CC_HOME/man/EN_US /usr/lpp/X11/Xamples/man /usr/lpp/X11/man /usr/man /usr/vacpp/man/EN_US /usr/opt/perl5/man /opt/csm/man $apacheHome/old/man $HOME/share/man $HOME/gnu/share/man $CLEARCASE/doc/man"
    ;;
  Linux)
    pathsList="/sbin /usr/sbin $CC_BIN $MQSAMPLE_BIN $TUX_BIN $CLEARCASE_BIN $ORACLE_BIN $apacheBin $CATool_Bin"
    manPathsList=""
    ;;
  HP-UX) ;;
  SunOS) ;;
  *) ;;
esac

for path in $pathsList
do
  addpath $path
done
export PATH

for manpath in $manPathsList
do
  addmanpath $manpath
done
export MANPATH

dnsSuffix=".$(dig -t CNAME $(hostname) +nocmd +search +noquestion | awk -F. '/^[^;].*CNAME/{print$2}')"
hostname | grep -q dnsSuffix && unset dnsSuffix

export newline="$(printf '\n\a')"
#PS1="$LOGNAME@$(hostname)$dnsSuffix:\$PWD$newline$ "

export red="\e[0;31m"
export green="\e[0;32m"
export blue="\e[0;34m"
export normal="\e[m"

export BOLD=$(tput smso)
export BRIGHT=$(tput bold)
export SURL=$(tput smul)
export NORMAL=$(tput sgr0)

if [ -s "$MAIL" ]           # This is at Shell startup.  In normal
then echo "$MAILMSG"        # operation, the Shell checks
fi                          # periodically.

test $OSType = AIX && export TERM=vt220

export JAVA_HOME=$(which java | sed "s:/bin/java::")

export XAUTHORITY=$HOME/.Xauthority

export APPUppercase=$(echo $APP | tr [:lower:] [:upper:])
export ENVIRON=v

ssh_connection_remoteIP=$(echo $SSH_CONNECTION | awk '{print $3}')
ssh_connection_remoteHostname=$(dig -x $ssh_connection_remoteIP +short | cut -d. -f1 | tr [:upper:] [:lower:])
echo "=> ssh_connection_remoteHostname = $ssh_connection_remoteHostname"
echo $ssh_connection_remoteHostname | egrep -q "^[dhbp]$APP[aivdm][12]?d$" && export ORACLE_SID=$(echo $ssh_connection_remoteHostname | sed s/.$/li/) && echo "=> ORACLE_SID = $ORACLE_SID"

test $ORACLE_SID && export TNS_ADMIN=/bases/oracle/$ORACLE_SID/admin/network

export APP_USER=${APP}${ENVIRON}adm
export mqmUser=${APP}vadm
export LOGDIR=/applis/$APP$ENVIRON/app/log
DATADIR=/applis/$APP$ENVIRON/app/data
export ulog=$DATADIR/log/ULOG.$(date +%m%d%y)

test $CLEARCASE && {
  ProjectRoot=$(cleartool lsvob -short | awk '/vob_/&&!/pvob/')/$(cleartool lscomp -short -invob $(cleartool lsvob -short | awk /pvob/))
  currentView=$(cleartool lsview -cview -short 2>/dev/null)
  currentActivity=$(cleartool lsact -cact -short 2>/dev/null)
  currentBaseLine=$(cleartool lsstream -fmt %[found_bls]p 2>/dev/null)
  currentStream=$(cleartool lsstream -short 2>/dev/null)
}

#ps -fu $USER | grep -v grep | grep -q ssh-agent || eval $(ssh-agent -s | tee $HOME/.ssh/.ssh-agent.vars)
#chmod 600 $HOME/.ssh/.ssh-agent.vars
#test $SSH_AUTH_SOCK || . $HOME/.ssh/.ssh-agent.vars

ps -fu $USER
export ENV=$HOME/.kshrc
type finger >/dev/null 2>&1 && echo "=> Liste des utilisateurs connectes:" && finger
#echo "=> Fin d'execution du .profile"

#set -x
type bash >/dev/null 2>&1 && {
  newline="\n"
  test $(id -gn) = cc-$APP && PS1="$blue$LOGNAME@$(hostname)$dnsSuffix:\w$newline\$ $normal" || PS1="$green$LOGNAME@$(hostname)$dnsSuffix:\w$newline\$ $normal"
  test $CLEARCASE_ROOT && {
    cd $ProjectRoot
    echo "$currentView" | grep -iq "${USER}_${APPUppercase}_int" && export PS1="[VIEW=$(echo $currentView)@${red}CACT="'$(cleartool lsact -cact -short 2>/dev/null)'"$green] $LOGNAME@$(hostname)$dnsSuffix:\$PWD$newline$ " || export PS1="[VIEW=$currentView@${red}BL="'$(cleartool lsstream -fmt %[found_bls]p 2>/dev/null)'"$green] $LOGNAME@$(hostname)$dnsSuffix:\$PWD$newline$ "
  }
  
  test $(id -gn) = cc-$APP && test -d "$ProjectRoot" && {
    cd $ProjectRoot
    echo "$currentView" | grep -iq "${USER}_${APPUppercase}_int" && export PS1="[VIEW=$currentView@${red}CACT="'$(cleartool lsact -cact -short 2>/dev/null)'"$blue] $LOGNAME@$(hostname)$dnsSuffix:\$PWD$newline$ " || export PS1="[VIEW=$currentView}BL="'$(cleartool lsstream -fmt %[found_bls]p 2>/dev/null)'"$blue] $LOGNAME@$(hostname)$dnsSuffix:\$PWD$newline$ "
  }
  set +x

  export PS1="$PS1$normal"

  exec bash
}

