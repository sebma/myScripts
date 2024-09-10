#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false
scriptBaseName=${0/*\//}

distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi
test $(id -u) == 0 && sudo="" || sudo=sudo

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variableDefinitionFile" >&2
	exit 1
fi

variableDefinitionFile="$1"
source "$variableDefinitionFile" || exit

if $isDebianLike;then
	grep ^Acquire.*$http_proxy /etc/apt/apt.conf.d/*proxy -q  || echo "Acquire::http::proxy  \"$http_proxy\";"  | $sudo tee /etc/apt/apt.conf.d/00aptproxy
	grep ^Acquire.*$https_proxy /etc/apt/apt.conf.d/*proxy -q || echo "Acquire::http::proxy  \"$https_proxy\";" | $sudo tee -a /etc/apt/apt.conf.d/00aptproxy
	$sudo grep '^[^#]\s*.*env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"' | $sudo tee -a /etc/sudoers.d/proxy
fi

if which git &>/dev/null;then
	git config --global http.proxy  $http_proxy
	git config --global https.proxy $https_proxy
 	git config --global -l | egrep https?.proxy
fi

if which snap &>/dev/null;then
	$sudo snap set system proxy.http=$http_proxy
	$sudo snap set system proxy.https=$https_proxy
	$sudo snap get system proxy
	snap debug connectivity
fi

exit
