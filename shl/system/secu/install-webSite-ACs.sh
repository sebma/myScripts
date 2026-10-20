#!/usr/bin/env bash

webSite=$1
acCertsDIR=/usr/local/share/ca-certificates
curl -sL $webSite >/dev/null
retCode=$?
if [ $retCode == 60 ];then
	fqdn=$(echo $webSite | cut -d/ -f3)
	openssl s_client -connect $fqdn:443 -showcerts < /dev/null 2>/dev/null | awk -v fqdn=$fqdn '
/-----BEGIN CERTIFICATE-----/ { certFileName=fqdn "-" n ".crt" }
certFileName && n { print > certFileName }
/-----END CERTIFICATE-----/ { close(certFileName); if(n)print certFileName; certFileName=""; n++ }
' | while read certFileName; do
		commonName=$(openssl x509 -noout -subject -in $certFileName | grep -oP '(?<=CN=).*' | sed 's/\s/-/g')
		sudo mv -v $certFileName $acCertsDIR/$commonName.crt
	done
	sudo update-ca-certificates
fi
