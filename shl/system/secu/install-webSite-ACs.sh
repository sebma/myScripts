#!/usr/bin/env bash

webSite=$1
read ID_LIKE <<< $(awk -F '[= ]' '/ID_LIKE/{gsub(/"/, "", $2); print $2}' /etc/os-release)
case $ID_LIKE in
	debian) acCertsDIR=/usr/local/share/ca-certificates;updateCAsCMD=update-ca-certificates;;
	rhel)   acCertsDIR=/etc/pki/ca-trust/source/anchors;updateCAsCMD=update-ca-trust;;
	*)
esac

curl -sL $webSite >/dev/null
retCode=$?
if [ $retCode == 60 ];then
	fqdn=${webSite#*://}
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
