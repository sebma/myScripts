#!/bin/env ksh

set -o errexit
set -o nounset
progName=$(basename $0)

main() {
  set -o errexit
  set -o nounset

  typeset -i freeSpace=$(LANG=C df -m . | awk '/[0-9]%/{print$3}')
  typeset -i minimumSpace=100
  
  typeset userPrefix=""
  echo "Saisir le prefix du user a utiliser."
  read userPrefix
  test $userPrefix || {
    echo "==> [$progName] ERROR: Vous devez saisir le prefix du user a utiliser." >&2
    return 0
  }

  if [ $freeSpace -lt $minimumSpace ]
  then
    echo "==> [$progName] ERROR: There is only $freeSpace MB free." >&2
    echo "==> [$progName] ERROR: You need at least $minimumSpace MB to run this installation, please free some space and re-run <$progName>." >&2
    return 1
  fi
  
  if [ ! -f .already_run ]
  then
    set +o errexit
    for zipFile in $(ls */*.zip)
    do
      echo "=> zipFile = $zipFile"
      zipDir=$(dirname $zipFile)
      echo "=> zipDir = $zipDir"
      unzip $zipFile -d $zipDir
      find $zipDir/ '(' -name lanceur.sql -o -name grant2role.sql -o -name creatsyn.sql ')' -exec cp -ivp {} {}.bak \;
      find $zipDir/ '(' -name lanceur.sql -o -name grant2role.sql -o -name creatsyn.sql ')' -exec chmod u+w {} +
      find $zipDir/ '(' -name lanceur.sql -o -name grant2role.sql -o -name creatsyn.sql ')' -exec sed -i s/ADD/PPF/g {} +
    done
    set -o errexit
    touch .already_run
  fi
  
  echo "Saisir le ORACLE_SID: "
  read ORACLE_SID
  while test ! $ORACLE_SID 
  do
    echo "==> [$progName] ERROR: Le SID saisi est vide, veuillez le resaisir:" >&2
    read ORACLE_SID
  done

  export ORACLE_SID
  echo "=> ORACLE_SID = $ORACLE_SID"
  ORAENV_ASK=NO . oraenv
  unset ORAENV_ASK
  
  echo "=> ORACLE_HOME = $ORACLE_HOME"
  echo $PATH | grep $ORACLE_HOME/bin && echo "=> [$progName] INFO: La variable PATH contient bien <$ORACLE_HOME/bin>." || {
    echo "==> [$progName] ERROR: La variable PATH ne contient pas <$ORACLE_HOME/bin>." >&2
    return 3
  }
  
  export NSL_LANG=FRENCH_FRANCE.WE8ISO8859P15
  
  environment=$(hostname | cut -c1 | tr [:lower:] [:upper:])
  
  echo "=> [$progName] INFO: Suppression du schema de <${userPrefix}_admin> ..."
  cd InitBase
  typeset credentials=${userPrefix}_admin/ppf_81665
  sqlplus -s /nolog <<-EOF
  	conn $credentials
  	@drop_schema.sql ${userPrefix}_admin
  	purge recyclebin;
  	/
EOF
  
  echo "=> [$progName] INFO: Verification que tous les objects du schema ont ete supprime ..."
  typeset -i user_objectsNumber=$(echo -e "set feedback off;\nselect object_type, object_name from user_objects;" | sqlplus -s $credentials | wc -l)
  if [ $user_objectsNumber != 0 ]
  then
    echo "==> [$progName] ERROR: Il reste <$user_objectsNumber> en base, il faut donc re-supprimer le schema" >&2
    return 4
  else
    echo "==> OK."
  fi
  
  echo "=> [$progName] INFO: Re-creation du schema de <${userPrefix}_admin> et maj des chemins ..."
  sqlplus -s /nolog <<-EOF
          conn $credentials
          @lanceur.sql $environment
          @maj_chemins.sql
          /
EOF
  
  echo "=> [$progName] INFO: Verification qu'il n'y a pas d'erreur dans les logs ..."
  typeset -i nbErrors=$(egrep "ORA-|SP2-" *.log | wc -l)
  if [ $nbErrors = 0 ]
  then
    echo "==> OK."
  else
    echo "==> [$progName] ERROR: Il y a <$nbErrors> dans les logs:" >&2
    egrep "ORA-|SP2-" *.log
    return 5
  fi
  
  echo "> [$progName] INFO: Affectation des privileges pour ${userPrefix}_admin ..."
  echo exit | sqlplus -s $credentials @grant2role.sql
  
  echo "> [$progName] INFO: Creation des synonymes pour ${userPrefix}_batch ..."
  credentials=${userPrefix}_batch/ppf_69062
  echo exit | sqlplus -s $credentials @creatsyn.sql
  echo "> [$progName] INFO: Creation des synonymes pour ${userPrefix}_user ..."
  credentials=${userPrefix}_user/ppf_64452
  echo exit | sqlplus -s $credentials @creatsyn.sql
  cd -

  chmod u+x *sh */*sh
  echo "=> [$progName] INFO: Installation des patch de base de donnees ..."
  cd InstallDelta
  ./installpatch.ksh $ORACLE_SID
  cd -
  echo "=> [$progName] INFO: Installation du parametrage specifique du progiciel ...."
  cd InstallParam
  ksh -x ./installparam.ksh $ORACLE_SID
  cd -
}

df -h .
main
df -h .
