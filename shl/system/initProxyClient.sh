#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false
scriptBaseName=${0/*\//}

distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

domainLowercase=${domain,,}
domainUppercase=${domain^^}

if $isDebianLike;then
	test $(id -u) == 0 && sudo="" || sudo=sudo
	grep ^Acquire.*$http_proxy /etc/apt/apt.conf.d/*proxy -q 2>/dev/null  || echo "Acquire::http::proxy  \"$http_proxy\";"  | $sudo tee /etc/apt/apt.conf.d/00aptproxy
	grep ^Acquire.*$https_proxy /etc/apt/apt.conf.d/*proxy -q 2>/dev/null || echo "Acquire::https::proxy \"$https_proxy\";" | $sudo tee -a /etc/apt/apt.conf.d/00aptproxy

	# Propagation des variables "http_proxy" et "https_proxy" aux "sudoers"
	$sudo grep '^\s*Defaults:%sudo env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* 2>/dev/null -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"' | $sudo tee -a /etc/sudoers.d/proxy_env
	$sudo grep "^\s*Defaults:%$adminGroup env_keep.*https_proxy" /etc/sudoers /etc/sudoers.d/* 2>/dev/null -q || echo "Defaults:%$adminGroup@$domainLowercase env_keep += \"http_proxy https_proxy ftp_proxy all_proxy no_proxy\"" | $sudo tee -a /etc/sudoers.d/proxy_env
	test -s /etc/sudoers.d/proxy_env  && sudo chmod 440 /etc/sudoers.d/proxy_env
fi

if which snap &>/dev/null;then
	$sudo snap get system proxy.http  2>/dev/null | grep proxy.http -q  || $sudo snap set system proxy.http=$http_proxy
	$sudo snap get system proxy.https 2>/dev/null | grep proxy.https -q || $sudo snap set system proxy.https=$https_proxy
	$sudo snap get system proxy
	snap debug connectivity
fi

if which git &>/dev/null;then
	git config --global http.proxy  | grep http -q || git config --global http.proxy  $http_proxy
	git config --global https.proxy | grep http -q || git config --global https.proxy $https_proxy
	git config --global -l | egrep https?.proxy
fi

echo "=> MAJ des depots ..."
sudo apt-get update >/dev/null

exit
