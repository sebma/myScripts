#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# != 2 ];then
	echo "=> Usage: $scriptBaseName variablesDefinitionFile version" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit
version=$2

declare {isDebian,isRedHat}Like=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	sudo=""
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	sudo=sudo
	isDebianLike=true
fi
test $(id -u) == 0 && sudo=""

if $isDebianLike;then
	if dpkg -l | grep glpi-agent -q;then
		echo "=> WARNING : GLPI-Agent is already installed, exiting ..."
		exit 2
	fi
elif $isRedHatLike;then
	if rpm -qa | grep glpi-agent -q;then
		echo "=> WARNING : GLPI-Agent is already installed, exiting ..."
		exit 2
	fi
fi

##################### DESINSTALLATION DE FUSION INVENTORY AGENT #####################
if $isDebianLike;then
	dpkg -l | grep fusioninventory-agent -q && $sudo apt purge  -V fusioninventory-agent -y
elif $isRedHatLike;then
	rpm -qa | grep fusioninventory-agent -q && $sudo yum remove -v fusioninventory-agent -y
fi

##################### INSTALLATION DU GLPI AGENT #####################

if snap list glpi-agent >/dev/null 2>&1;then
	echo "=> WARNING : GLPI-Agent is already installed as a SNAP package." >&2
	exit 3
fi

if which -a glpi-agent -q;then
	echo "=> WARNING : GLPI-Agent is already installed in $(which -a glpi-agent)." >&2
	exit 4
fi

mkdir -pv $HOME/glpi-agent/ $HOME/log/
if ! grep -am1 "VERSION.*${version}" $HOME/glpi-agent/glpi-agent-${version}-linux-installer.pl -q 2>/dev/null;then
	echo "=> Downloading glpi-agent-${version}-linux-installer.pl ..."
	if ! wget -nv -P $HOME/glpi-agent/ -nc https://github.com/glpi-project/glpi-agent/releases/download/$version/glpi-agent-${version}-linux-installer.pl;then
		echo "=> ERROR: Failed downloading <glpi-agent-${version}-linux-installer.pl>." >&2
		exit 5
	fi
fi

if grep -am1 "VERSION.*${version}" $HOME/glpi-agent/glpi-agent-${version}-linux-installer.pl -q;then
	echo "=> Installing glpi-agent-${version}-linux-installer.pl ..."
	glpiInstallerLog=$HOME/log/glpi-agent-${version}-linux-installer-$(date +%Y-%m-%d-%HH%MM%S).log

	$sudo perl $HOME/glpi-agent/glpi-agent-${version}-linux-installer.pl -v --logfile=/var/log/glpi-agent.log --service --server=https://$GLPI_Inventory_Server_FQDN/marketplace/glpiinventory --type=$listOfComponents --httpd-trust=$httpdTrustList  --logger=syslog,stderr --logfacility=LOG_DAEMON --install 2>&1 | tee -a $glpiInstallerLog
	if [ $? == 0 ];then
		#test -f /etc/glpi-agent/agent.cfg || $sudo cp -piv /usr/share/glpi-agent/etc/agent.cfg /etc/glpi-agent/agent.cfg

		### POUR POINTER SUR LE GLPI INVENTORY SERVER ###
		# egrep "^server = .*helpdesk" /etc/glpi-agent/agent.cfg || $sudo sed -r -i".ORIG" "s|.*httpd-trust.*|httpd-trust = $httpdTrustList|;0,/server.*=/s|^#?server =.*|server = https://$GLPI_Inventory_Server_FQDN/marketplace/glpiinventory/|;s/^logger.*/logger = syslog,stderr/;s/^logfacility.*/logfacility = LOG_DAEMON/" /etc/glpi-agent/agent.cfg

		echo "=> Voici les parametre de </etc/glpi-agent/conf.d/00-install.cfg>."
		egrep -v "^(\s*#|$|^;)" /etc/glpi-agent/conf.d/00-install.cfg

		$sudo systemctl restart glpi-agent.service
		systemctl status glpi-agent.service
		journalctl -u glpi-agent --no-pager -e
	else
		echo "=> ERROR: The installation with <glpi-agent-${version}-linux-installer.pl> failed." >&2
		exit 6
	fi
else
	echo "=> ERROR: Could not download <glpi-agent-${version}-linux-installer.pl> through <$proxy>." >&2
	exit 7
fi
