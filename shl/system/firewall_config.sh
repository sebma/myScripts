#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# != 2 ];then
	echo "=> Usage: $scriptBaseName variablesDefinitionFile version" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit
version=$2

declare {isDebian,isRedHat}Like=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	sudo=""
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	sudo=sudo
	isDebianLike=true
fi
test $(id -u) == 0 && sudo=""

if $isDebianLike;then
	dpkg -s ufw &>/dev/null || $sudo apt install -V ufw
	$sudo ufw allow ssh
	$sudo ufw allow 1022/tcp comment "do-release-upgrade alternate SSH port"
	$sudo ufw allow 2002/tcp comment "LogMeIn Host"
	$sudo ufw allow 62354/tcp comment "GLPI-Agent"
	$sudo ufw enable
fi
