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
arch=$(dpkg --print-architecture)

downloadURL=$(curl -s https://api.github.com/repos/$repoUser/$repoName/releases/latest | jq -r ".assets[] | select(.name|match(\"linux_$arch.tar.gz\$\")).browser_download_url")
echo "=> downloadURL = <$downloadURL>"
test -n "$downloadURL" && wget -nc -nv -P/tmp "$downloadURL" && archiveName=$(basename "$downloadURL")
if [ -n "$archiveName" ];then
	cd /tmp
	tar -xvf /tmp/$archiveName
	gzip -9 yq.1
	$sudo install -vpm755 yq_linux_$arch /usr/local/bin/yq
	$sudo install -vpm755 yq.1.gz /usr/local/share/man/man1/
	rm yq_linux_$arch yq.1.gz install-man-page.sh
	cd - >/dev/null
	which yq >/dev/null && yq -V
fi
