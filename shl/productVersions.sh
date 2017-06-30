#!/bin/sh

set -o errexit

hostname | grep -q "^d" && listEnv="v|m|i" || listEnv="f|t"
test $# -eq 0 && {
  echo "=> Usage: <$0> <lettre de l'environement:$listEnv>" >&2
  exit 1
}

app=xyz
env=$1
echo $env | egrep -q "$listEnv" || {
  echo "=> ERROR: Wrong environment chosen, please choose between: $listEnv."
  exit 2
}

envUpper=`echo $env | tr [:lower:] [:upper:]`
userApplicatif=${app}${env}adm
tomApplicatif=tom${app}${env}
webApplicatif=${app}${env}web

local TUXDIR=$(ls -1d -t /produits/tuxedo/tuxedo*/ | egrep "tuxedo[0-9]+/$" | head -1)
. $TUXDIR/tux.env

printf "=> Version de TUXEDO: "; tmadmin -v 
echo ; printf "=> Version de SQLPlus: "; sqlplus -V
printf "=> Release TOM: " && head -1 /produits/tom/$app$env/.release
echo
printf "=> Version de IBM MQ: "
dspmqver
echo
printf "=> Version de Apache: "
local apacheHome=$(ls -1d -t /produits/composants/apache/apache*/ | head -1)
$apacheHome/bin/apachectl -v
#sudo su - $userApplicatif -c '$ELA_DIR/app/apache/domaineELA/bin/apachectl -v '
echo
printf "=> Version de WebLogic: "

local WL_HOME=$(ls -1d -t /produits/weblogic/weblogic*/wlserver_*/ | egrep "wlserver_[0-9]+.[0-9]+/$" | head -1)
. "${WL_HOME}/common/bin/commEnv.sh"

java -cp $WEBLOGIC_CLASSPATH weblogic.version -verbose | awk '/WebLogic Server [0-9]/{print$3}'
#echo version | $WL_HOME/common/bin/wlst.sh

echo

echo "=> Liste des Patch WebLogic: "
cd $BEA_HOME/utils/bsu && ./bsu.sh -report | egrep "Patch ID|Description"
