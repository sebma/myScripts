#!/usr/bin/env bash

source <(grep -w ID_LIKE /etc/os-release)
if test -n "$ID_LIKE";then
	distribFamily=( $ID_LIKE )
else
	source <(grep -w ID /etc/os-release)
	distribFamily=$ID
fi

case $distribFamily in
	debian|alpine) acCertsDIR=/usr/local/share/ca-certificates;updateCAsCMD=update-ca-certificates;;
	rhel) acCertsDIR=/etc/pki/ca-trust/source/anchors;updateCAsCMD=update-ca-trust;;
	arch) acCertsDIR=/etc/ca-certificates/trust-source/anchors/;updateCAsCMD=update-ca-trust;;
	*) ;;
esac

webSite=$1
curl -I $webSite >/dev/null
retCode=$?
if [ $retCode == 60 ];then
	fqdn=${webSite#http*://}
	fqdn=${fqdn%%/*}
	[[ $fqdn == *:* ]] && port=${fqdn#*:} || port=443
	fqdn=${fqdn%:*}
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
