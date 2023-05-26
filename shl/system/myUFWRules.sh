#!/usr/bin/env sh

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo="command sudo" || sudo=""

grep Anydesk /etc/ufw/applications.d/* -q || cat <<EOF | $sudo tee /etc/ufw/applications.d/anydesk
[Anydesk]
title=The fastest remote desktop software on the market.
description=Anydesk allows for new usage scenarios and applications that have not been possible with current remote desktop software.
ports=7070/tcp
EOF

grep Kodi /etc/ufw/applications.d/* -q || cat <<EOF | $sudo tee /etc/ufw/applications.d/kodi
[Kodi]
title=Kodi Media Center
description=Kodi, formerly known as XBMC Media Center, is a software media-player and entertainment hub for all your digital media.
# Ports specifiques a mon Kodi
ports=8080,9090,9777/tcp
EOF

for lan in 192.168.0.0/24 192.168.1.0/24;do
	for app in OpenSSH Kodi Anydesk;do
		$sudo ufw allow from $lan to any app $app
	done
done

$sudo ufw status | grep inactive -q && $sudo ufw enable
$sudo ufw status
