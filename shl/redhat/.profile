echo "=> Debut d'execution du .profile"
set -o nolog
typeset -r | grep -q TMOUT= || unset TMOUT
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

amqsbcgPATH=$(which amqsbcg 2>/dev/null || find /usr/ /produits/ /opt/ -name amqsbcg -type f 2>/dev/null | grep -v MQSeriesSamples | head -1)
test $amqsbcgPATH && {
  MQSAMPLE_BIN=$(dirname $amqsbcgPATH)
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
    pathsList="/usr/ucb $CC_BIN $MQSAMPLE_BIN /opt/opsware/agent/bin $CLEARCASE_BIN $ORACLE_BIN $apacheBin $CATool_Bin"
    manPathsList="$CC_HOME/man/EN_US /usr/lpp/X11/Xamples/man /usr/lpp/X11/man /usr/man /usr/vacpp/man/EN_US /usr/opt/perl5/man /opt/csm/man $apacheHome/old/man $HOME/share/man $HOME/gnu/share/man $CLEARCASE/doc/man"
    ;;
  Linux)
    pathsList="$CC_BIN $MQSAMPLE_BIN $TUX_BIN $CLEARCASE_BIN $ORACLE_BIN $apacheBin $CATool_Bin"
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

export normal="\033[m"
export bright="\033[1m"
export red="\033[0;31m"
export green="\033[0;32m"
export yellow="\033[33m"
export blue="\033[34m"
export magenta="\033[35m"
export cyan="\033[36m"
export grey="\033[37m"

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
printf "=> ssh_connection_remoteHostname = $bright$cyan$ssh_connection_remoteHostname$normal\n"

isDev=$(hostname | cut -c1 | grep -iq 'D' && echo true || echo false)
if echo $ssh_connection_remoteHostname | grep -q eurlx
then
  export REP_APPLICATIF=/applis/eurv2
  export LV_DEPOT=/applis/eurc/livraison
else
  if $isDev
  then
    envir=$(echo $ssh_connection_remoteHostname | cut -c2-6)
  else
    envir=$(echo $ssh_connection_remoteHostname | cut -c2-5)
  fi

  export REP_APPLICATIF=/applis/$envir
  export LIVRAISON_REP=$REP_APPLICATIF/livraisons
  case $envir in
    ${APP}v1|${APP}i1) export LV_DEPOT=/applis/${APP}c/livraison ;;
    ${APP}v2|${APP}d1) export LV_DEPOT=/applis/${APP}v2/livraisons ;;
    ${APP}f|${APP}t)   export LV_DEPOT=/applis/netapp/$envir/share/livraison ;;
    ${APP}p)           export LV_DEPOT=/applis/NetApp/$envir/share/livraison ;;
    *) ;;
  esac
fi

#case $(hostname) in
#  DEURLX01)
#    export REP_APPLICATIF=/applis/euri1
#  ;;
#  DEURLX02)
#  ;;
#  HEURLX01|HEURLX02|HEURLX03)
#    export REP_APPLICATIF=/applis/eurf
#  ;;
#  HEURLX01|HEURLX02|HEURLX04)
#    export REP_APPLICATIF=/applis/eurt
#  ;;
#  PEURLX01|PEURLX02|PEURLX03)
#    export REP_APPLICATIF=/applis/eurp
#  ;;
#  *) ;;
#esac

serverPrefix=$(hostname | cut -c1 | tr [:upper:] [:lower:])
echo $ssh_connection_remoteHostname | egrep -iq "${APP}0[1-9]|d${APP}..d$|h${APP}[ft]01b$|p${APP}p01b" && {
  if $isDev
  then
    envir=$(echo $ssh_connection_remoteHostname | cut -c2-6)
  else
    envir=$(echo $ssh_connection_remoteHostname | cut -c2-5)
  fi
  export ORACLE_SID=$serverPrefix${envir}li
  export ORACLE_SID_ARCH=$serverPrefix${envir}ar
}

#case $ssh_connection_remoteHostname in
#  d${APP}v1) export ORACLE_SID=d${APP}v1$APP ;;
#  d${APP}i1) export ORACLE_SID=d${APP}i1$APP ;;
#  d${APP}a1) export ORACLE_SID=d${APP}a1$APP ;;
#  d${APP}v2) export ORACLE_SID=d${APP}v2$APP ;;
#  d${APP}d1) export ORACLE_SID=d${APP}v2$APP ;;
#  *);;
#esac

test $ORACLE_SID && printf "=> ORACLE_SID = $bright$cyan$ORACLE_SID$normal\n" && export TNS_ADMIN=/bases/oracle/$ORACLE_SID/admin/network

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


#Defini entre autre la variable LV_DEPOT
test $ORACLE_SID || . $HOME/.liv/_livrc.ksh

echo "=> MIT-MAGIC-COOKIE-1:"
xauth list | grep :$(echo $DISPLAY | awk -F '\\.|:' '{print$2}')
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

  echo "=> Fin d'execution du .profile"
  exec bash
}

echo "=> Fin d'execution du .profile"
