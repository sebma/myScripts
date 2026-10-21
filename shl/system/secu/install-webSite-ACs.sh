#!/usr/bin/env bash

source <(grep ID_LIKE /etc/os-release)
ID_LIKE=( $ID_LIKE )
case $ID_LIKE in
	debian) acCertsDIR=/usr/local/share/ca-certificates;updateCAsCMD=update-ca-certificates;;
	rhel)   acCertsDIR=/etc/pki/ca-trust/source/anchors;updateCAsCMD=update-ca-trust;;
	*) ;;
esac

webSite=$1
curl -sL $webSite >/dev/null
retCode=$?
if [ $retCode == 60 ];then
	fqdn=${webSite#http*://}
	fqdn=${fqdn%%/*}
	openssl s_client -connect $fqdn:443 -showcerts < /dev/null 2>/dev/null | awk -v fqdn=$fqdn '
/-----BEGIN CERTIFICATE-----/ { certFileName=fqdn "-" n ".crt" }
certFileName && n { print > certFileName }
/-----END CERTIFICATE-----/ { close(certFileName); if(n)print certFileName; certFileName=""; n++ }
' | while read certFileName; do
		commonName=$(openssl x509 -noout -subject -in $certFileName | grep -oP '(?<=CN=).*' | sed 's/\s/-/g')
		sudo mv -v $certFileName $acCertsDIR/$commonName.crt
	done
	sudo $updateCAsCMD
fi
