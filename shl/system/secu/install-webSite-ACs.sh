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
curl -sI $webSite >/dev/null
retCode=$?

fqdn=${webSite#http*://}
fqdn=${fqdn%%/*}
[[ $fqdn =~ ":" ]] && port=${fqdn#*:} && fqdn=${fqdn%:*} || port=443

type -P openssl >/dev/null && openssl s_client -connect $webSite:$port < /dev/null 2>/dev/null | grep s:.*CN.
type -P gnutls-cli >/dev/null && gnutls-cli $webSite -p $port < /dev/null | grep 'subject\s*.CN=[^,]*'
type -P gnutls-cli >/dev/null && gnutls-cli --print-cert $webSite -p $port --save-cert $webSite-test.crt < /dev/null >/dev/null
grep CERT $webSite-test.crt
curl -sSw '%{certs}' -o /dev/null $webSite | egrep '(Subject|Issuer):'

if [ $retCode == 60 ];then
#	gnutls-cli --print-cert $webSite -p $port </dev/null \
#	curl -sSw '%{certs}' -o /dev/null $webSite \
	openssl s_client -connect $fqdn:$port -showcerts < /dev/null 2>/dev/null \
		| awk -v fqdn=$fqdn '
n && /-----BEGIN CERTIFICATE-----/ { certFileName=fqdn "-" n ".crt" }
n && certFileName { print > certFileName }
/-----END CERTIFICATE-----/ {if(n++) { close(certFileName);print certFileName;certFileName="" } }
' | while read certFileName; do
		commonName=$(openssl x509 -noout -subject -in $certFileName | grep -oP '(?<=CN=).*' | sed 's/\s/-/g')
		sudo mv -v $certFileName $acCertsDIR/$commonName.crt
		# To test, type :
		# sudo rm $acCertsDIR/$commonName.crt -vf && sudo update-ca-certificates -f
		# and re-run this script.
	done
	sudo $updateCAsCMD
fi

