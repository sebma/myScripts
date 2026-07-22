#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
elRelease=$(source /etc/os-release;echo $VERSION_ID)

wget "https://repo.zabbix.com/zabbix/7.0/rhel/$elRelease/x86_64/zabbix-release-latest-7.0.el$elRelease.noarch.rpm"
unset http_proxy https_proxy
yum clean all
$sudo yum clean all
$sudo yum install -v ./zabbix-release_latest_7.0.el$elRelease.noarch.rpm
$sudo yum install -v zabbix-agent2
$sudo systemctl restart zabbix-agent2
$sudo systemctl enable zabbix-agent2

majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)
if [ $majorNumber -ge 18 ];then
	systemctl --quiet is-active postgresql || $sudo yum install -v zabbix-agent2-plugin-postgresql
	systemctl --quiet is-active mongodb || $sudo yum install -v zabbix-agent2-plugin-mongodb
	systemctl --quiet is-active mssql-server || $sudo yum install -v zabbix-agent2-plugin-mssql
	systemctl --quiet is-active mariadb || $sudo yum install -v zabbix-agent2-plugin-mssql
fi
