#!/usr/bin/env bash

Distrib=""
Distrib=`awk '{print $1}' /etc/issue`
[ -z "$Distrib" ] && Distrib=`grep -q "=" /etc/*-release && head -1 /etc/*-release | cut -d'=' -f2 || awk '{print $1}' /etc/*-release`

IFace=$(ifconfig -a | grep "Ethernet" | head -1 | cut -d' ' -f1)
echo "=> IFace=$IFace"

#echo Distrib=$Distrib

case $Distrib in
  Gentoo)
    echo La distrib est une Gentoo
    lspci | grep -Eiq "atheros.*(802.11|wireless)" && {
      set -x
      lsmod | grep -q ath_pci || modprobe ath_pci 2>/dev/null || ( depmod -a && modprobe ath_pci )
      set +x
    }
    break
  ;;
  Debian|Ubuntu)
    echo La distrib est une Debian/Ubuntu
    lspci | grep -Eiq "atheros.*(802.11|wireless)" && {
      set -x
      lsmod | grep -q ath_pci || sudo modprobe ath_pci 2>/dev/null || ( sudo depmod -a && sudo modprobe ath_pci )
      set +x

    }
  break
  ;;
  *)
    echo La Distrib est autre
    break
  ;;
esac

#set -x
ifconfig $IFace | grep -q "UP " || sudo ifconfig $IFace up
#ifconfig wifi0 | grep -q "UP " || sudo ifconfig wifi0 up
WPA_CONFIG=/etc/wpa_supplicant/wpa_supplicant.conf

[ ! -e "$WPA_CONFIG" ] && sudo touch $WPA_CONFIG

sudo grep -q 'ctrl_interface=/var/run/wpa_supplicant' $WPA_CONFIG || sudo sh -c "echo ctrl_interface=/var/run/wpa_supplicant\"\n\" >> $WPA_CONFIG "
sudo grep -q 'ctrl_interface_group=0' $WPA_CONFIG || sudo sh -c "echo ctrl_interface_group=0\"\n\" >> $WPA_CONFIG "


sudo grep -q 'network={' $WPA_CONFIG || sudo sh -c "echo network={ >> $WPA_CONFIG"

MyNetworkSSID=sebfreebox
for param in ssid=\\\"$MyNetworkSSID\\\" proto=WPA key_mgmt=WPA-PSK \#pairwise=CCMP \#group=CCMP
do
	sudo grep -q "$param" $WPA_CONFIG || sudo sh -c "echo \"\t\"$param >> $WPA_CONFIG"
done

#sudo grep -q "psk=" $WPA_CONFIG || sudo sh -c "echo \#\"\t\"psk=\\\"\\\" >> $WPA_CONFIG"
sudo grep -q "psk=" $WPA_CONFIG || sudo sh -c "wpa_passphrase $MyNetworkSSID < $(dirname $0)/toto | grep \"[^#]psk\" >> $WPA_CONFIG"
sudo grep -q '}' $WPA_CONFIG || sudo sh -c "echo } >> $WPA_CONFIG"

echo "=> DEBUG: kernel v$(uname -r)" > $(dirname $0)/wpa_supplicant.log
lshw | grep -A12 network:1 >> $(dirname $0)/wpa_supplicant.log
echo "=> DEBUG: modinfo ath_pci $(modinfo ath_pci)\n" >> $(dirname $0)/wpa_supplicant.log

grep -q "psk=....*" $WPA_CONFIG && {
#	sudo sh -xc "/etc/init.d/wpa-ifupdown start"
	sudo wpa_supplicant -w -dd -i $IFace -c $WPA_CONFIG -Dmadwifi >> $(dirname $0)/wpa_supplicant.log 2>&1
	sync
#	cat /etc/wpa_supplicant/wpa_supplicant.conf
#	sudo chmod 700 $WPA_CONFIG
	sleep 5
	sudo dhclient $IFace || sudo dhcpcd $IFace || sudo pump $IFace
}

set +x

