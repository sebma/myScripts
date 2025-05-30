#!/usr/bin/env sh

scriptBaseName=${0/*\//}
if [ $# != 0 ];then
	echo "=> Usage $scriptBaseName" >&2
	exit 1
fi
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

isDebianLike=false
isRedHatLike=false
isAlpineLike=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
elif echo $distribID | egrep "alpine" -q;then
	isAlpineLike=true
fi

test -z $http_proxy  && echo "=> [$scriptBaseName] ERROR : http_proxy is not defined." >&2 && exit 2
test -z $https_proxy && echo "=> [$scriptBaseName] ERROR : https_proxy is not defined." >&2 && exit 3
test -z $no_proxy    && echo "=> [$scriptBaseName] ERROR : no_proxy is not defined." >&2 && exit 4

if $isDebianLike;then
	grep ^Acquire.*$http_proxy  /etc/apt/apt.conf.d/*proxy* -q 2>/dev/null || echo "Acquire::http::proxy  \"$http_proxy\";"  | $sudo tee /etc/apt/apt.conf.d/00aptproxy
	grep ^Acquire.*$https_proxy /etc/apt/apt.conf.d/*proxy* -q 2>/dev/null || echo "Acquire::https::proxy \"$https_proxy\";" | $sudo tee -a /etc/apt/apt.conf.d/00aptproxy
elif $isRedHatLike;then
	egrep "proxy\s*=\s*[0-9.]+" /etc/yum.conf || echo "proxy = $https_proxy" | $sudo tee -a /etc/yum.conf
elif $isAlpineLike;then
	: # apk utilise la variable "https_proxy"
fi

if test -f /etc/sudoers;then
	# Propagation des variables "http_proxy", "https_proxy" et "no_proxy" aux "sudoers"
	$sudo grep '^\s*Defaults:%sudo env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* 2>/dev/null -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"' | $sudo tee -a /etc/sudoers.d/proxy_env
	test -s /etc/sudoers.d/proxy_env && sudo chmod 640 /etc/sudoers.d/proxy_env
fi

if which snap &>/dev/null;then
	$sudo snap get system proxy.http  2>/dev/null | grep proxy.http -q  || time $sudo snap set system proxy.http=$http_proxy
	$sudo snap get system proxy.https 2>/dev/null | grep proxy.https -q || time $sudo snap set system proxy.https=$https_proxy
	$sudo snap get system proxy
	snap debug connectivity
fi

if which git &>/dev/null;then
	git config --global http.proxy  | grep http -q || git config --global http.proxy  $http_proxy
	git config --global https.proxy | grep http -q || git config --global https.proxy $https_proxy
	git config --global -l | egrep https?.proxy
fi

if which npm &>/dev/null;then
	npm config set proxy $http_proxy
	npm config set https-proxy $https_proxy
	npm config get proxy https-proxy
fi

if which cpan &>/dev/null;then
#	printf "o conf http_proxy $http_proxy\no conf commit" | cpan
	:
fi

if which docker &>/dev/null;then
	cat <<-EOF | $sudo tee /root/.docker/config.json >/dev/null
{
	"proxies": {
		"default": {
			"httpProxy": "$http_proxy",
			"httpsProxy": "$httpsProxy",
			"noProxy": "$no_proxy"
		}
	}
}
EOF
fi

if which dockerd &>/dev/null;then
	cat <<-EOF | $sudo tee /etc/docker/daemon.json >/dev/null
{
	"proxies": {
		"http-proxy": "$http_proxy",
		"https-proxy": "$httpsProxy",
		"no-proxy": "$no_proxy"
	}
}
EOF
	$sudo systemctl restart docker
fi

exit
