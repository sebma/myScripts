#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
# majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)

if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

if $isDebianLike;then
	test $(id -u) == 0 && sudo="" || sudo=sudo

		# CONFIG EXIM4
		cat <<-EOF | sudo tee /etc/exim4/update-exim4.conf.conf >/dev/null
	# /etc/exim4/update-exim4.conf.conf
	#
	# Edit this file and /etc/mailname by hand and execute update-exim4.conf
	# yourself or use 'dpkg-reconfigure exim4-config'
	#
	# Please note that this is _not_ a dpkg-conffile and that automatic changes
	# to this file might happen. The code handling this will honor your local
	# changes, so this is usually fine, but will break local schemes that mess
	# around with multiple versions of the file.
	#
	# update-exim4.conf uses this file to determine variable values to generate
	# exim configuration macros for the configuration file.
	#
	# Most settings found in here do have corresponding questions in the
	# Debconf configuration, but not all of them.
	#
	# This is a Debian specific file

	dc_eximconfig_configtype='satellite'
	dc_other_hostnames='$HOSTNAME'
	dc_local_interfaces='127.0.0.1 ; ::1'
	dc_readhost='$glpiSERVER_FQDN'
	dc_relay_domains=''
	dc_minimaldns='true'
	dc_relay_nets=''
	dc_smarthost='$smtpSmartHost'
	CFILEMODE='644'
	dc_use_split_config='true'
	dc_hide_mailname='true'
	dc_mailname_in_oh='true'
	dc_localdelivery='mail_spool'
EOF

	$sudo cp -puv /etc/hostname /etc/mailname
	$sudo update-exim4.conf
fi
