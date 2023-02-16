#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false
distribID=$(source /etc/os-release;echo $ID)
if echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
	sudo=""
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	sudo=sudo
fi
test $(id -u) == 0 && sudo=""

#cf. https://superuser.com/q/1765288/528454
for iface in $(ip -o a | awk '/inet6/{gsub("\\.","/",$2);print$2}');do
	$sudo sysctl -w net.ipv6.conf.$iface.disable_ipv6=1
	grep $iface.disable_ipv6=1 /etc/sysctl.conf -q || echo net.ipv6.conf.$iface.disable_ipv6=1 | $sudo tee -a /etc/sysctl.conf
done

if $isDebianLike;then
	# SUR UBUNTU, si "netplan" est utilise, il faut aussi ajouter "link-local: []" dans le fichier YAML : "/etc/netplan/00-installer-config.yaml" : A IMPLEMENTER avec yq
	if nmcli connection show >/dev/null;then 
		nmcli connection show | sed -n '2,$ p' | awk '{print$1}' | while read connection;
		do
			$sudo nmcli connection modify $connection ipv6.method disabled
		done
		if [ -z "$SSH_CONNECTION" ];then
			$sudo systemctl restart NetworkManager
		fi
	fi
fi
ip -o a | grep inet6
