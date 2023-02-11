#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
if echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
	sudo=""
elif echo $distribID | egrep "debian|ubuntu" -q;then
	sudo=sudo
	isDebianLike=true
fi

test $(id -u) == 0 && sudo=""

repoUser=mikefarah
repoName=yq

downloadURL=$(curl -s https://api.github.com/repos/$repoUser/$repoName/releases/latest | jq -r '.assets[] | select(.name|match("linux_amd64.tar.gz$")).browser_download_url')
wget -nc -nv -P/tmp "$downloadURL"
archiveName=$(basename "$downloadURL")
tar -C/tmp -xvf /tmp/$archiveName
gzip -9 yq.1
sudo install -vpm755 yq_linux_amd64 /usr/local/bin/yq
sudo install -vpm755 yq.1.gz /usr/local/share/man/man1/
