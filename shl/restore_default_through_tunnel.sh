#!/bin/sh

leasesFile=$(locate -r "dhclient.leases$")
Interface=$(route -n | egrep -v "tun0|wlan|lo|^0.0.0.0|169.254" | awk '/^[0-9]/{print$NF}' | sort -u)
# Address=$(ip addr show $Interface | awk '/inet/{print $2}' | cut -d/ -f1)
pgrep vpn && GateWay=$(route -n | egrep -v "tun| 0.0.0.0" | awk '/^[0-9]/{print$2}') || GateWay=$(route -n | grep "^0.0.0.0" | awk '{print$2}')
echo "=> Interface=$Interface"
echo "=> GateWay=$GateWay"

route -n | egrep "^(10|0).0.0.0 .*tun" >/dev/null || {
  set -x
  sudo route del default
  sudo route add -net 10.0.0.0/8 dev tun0
  sudo route add -net 192.168.50.0/24 dev tun0
  sudo route add default gw $GateWay dev $Interface
}

grep "nameserver 10.156" /etc/resolv.conf >/dev/null || {
  echo "nameserver 10.156.4.53\nnameserver 10.156.4.54" >> ~/resolv.conf.new
  sudo mv -v ~/resolv.conf.new /etc/resolv.conf
}

for zone in sephora-eu.adam.net adam.net ams.sephora.fr
do
  grep "search .* $zone" /etc/resolv.conf >/dev/null || sudo sed -i -e "/search/s/$/ $zone/" /etc/resolv.conf
done
