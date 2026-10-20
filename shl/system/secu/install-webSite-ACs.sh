#!/usr/bin/env bash

webSite=$1
acCertsDIR=/usr/local/share/ca-certificates
curl -sL $webSite >/dev/null
retCode=$?
if [ $retCode == 60 ];then
	webSite=$(echo $webSite | cut -d/ -f3)
	openssl s_client -connect $webSite:443 -showcerts </dev/null 2>/dev/null | sudo awk -v webSite=$webSite '
/-----BEGIN CERTIFICATE-----/ { certFileName=webSite "-" n ".crt" }
certFileName && n { print > certFileName }
/-----END CERTIFICATE-----/ { close(certFileName); if(n)print certFileName; certFileName=""; n++ }
' | while read certFileName; do
	commonName=$(openssl x509 -noout -subject -in $certFileName | grep -oP '(?<=CN=).*' | sed 's/\s/-/g')
	sudo mv -v $certFileName $acCertsDIR/$commonName.crt
done
fi
sudo update-ca-certificates
