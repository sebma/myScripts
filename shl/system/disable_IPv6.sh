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

for iface in $(ip -o a | awk '/inet6/{gsub("\\.","/",$2);print$2}');do #cf. https://superuser.com/q/1765288/528454
        $sudo sysctl -w net.ipv6.conf.$iface.disable_ipv6=1
        grep $iface.disable_ipv6=1 /etc/sysctl.conf -q || echo net.ipv6.conf.$iface.disable_ipv6=1 | $sudo tee -a /etc/sysctl.conf
done

# SUR UBUNTU, si "netplan" est utilise, il faut aussi ajouter "link-local: []" dans le fichier YAML : "/etc/netplan/00-installer-config.yaml" : A IMPLEMENTER
ip -o a
