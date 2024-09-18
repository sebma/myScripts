#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# == 0 ];then
	echo "=> Usage : $scriptBaseName AC1.pem [AC2.pem] ..."
	exit -1
fi

let nb=0
for cert;do 
	certBaseName=${cert//*\//}
	echo "=> Installing <$certBaseName> ..."
	sudo cp -puv "$cert" "/usr/local/share/ca-certificates/${certBaseName/%.pem/.crt}" && let nb+=1
done
[ $nb != 0 ] && sudo update-ca-certificates && echo "=> Showing new certificate CAs in /etc/ssl/certs/ ..." && for cert
do
	certBaseName=${cert//*\//}
	ls -l /etc/ssl/certs/ | grep "$certBaseName"
done

# https://mozilla.github.io/policy-templates/#certificates--install
echo "=> Installing certificates for Firefox (SNAP)"
firefoxCertDIR=/etc/firefox/policies/certificates
firefoxPolicyDIR=/etc/firefox/policies
sudo mkdir -pv $firefoxPolicyDIR
sudo ln -vsf /usr/local/share/ca-certificates /etc/firefox/policies/certificates
sudo touch /etc/firefox/policies/policies.json
printf '{
  "policies": {
    "Certificates": {
      "Install": [' | sudo tee /etc/firefox/policies/policies.json >/dev/null

for cert;do
	certBaseName=${cert//*\//}
	certPath=$firefoxCertDIR/$certBaseName
#	echo "=> Installing <$certBaseName> ..." >&2
	printf "\n[\"$certBaseName\", \"$certPath\"]," | sudo tee -a /etc/firefox/policies/policies.json toto.json >/dev/null
done
sudo sed -i '$s/],[[:space:]]*$/]/' /etc/firefox/policies/policies.json
echo "
      ]
    }
  }
}
" | sudo tee -a /etc/firefox/policies/policies.json >/dev/null
jq < /etc/firefox/policies/policies.json

echo "=> Done."
