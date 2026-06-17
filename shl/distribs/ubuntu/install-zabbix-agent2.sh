#!/usr/bin/env bash

ubuntuRelease=$(source /etc/os-release;echo $VERSION_ID)
wget "https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu${ubuntuRelease}_all.deb"
unset http_proxy https_proxy
sudo apt install -V ./zabbix-release_latest_7.0+ubuntu${ubuntuRelease}_all.deb
sudo apt update
sudo apt install -V zabbix-agent2
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2
majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)
if [ $majorNumber -ge 18 ];then
	systemctl --quiet is-active postgresql || sudo apt install -V zabbix-agent2-plugin-postgresql
	systemctl --quiet is-active mongodb || sudo apt install -V zabbix-agent2-plugin-mongodb
	systemctl --quiet is-active mssql-server || sudo apt install -V zabbix-agent2-plugin-mssql
	systemctl --quiet is-active mariadb || sudo apt install -V zabbix-agent2-plugin-mssql
fi
