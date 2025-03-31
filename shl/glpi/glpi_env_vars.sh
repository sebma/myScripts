#!/usr/bin/env bash

export apachePHP_USER=www-data
export GLPI_ROOT=/var/www/path_to_glpi_web_pages # To adapt
export GLPI_CONFIG_DIR=$(awk -F"'" '/define.*GLPI_CONFIG_DIR/{print$(NF-1)}' $GLPI_ROOT/inc/downstream.php)
export GLPI_VAR_DIR=$(awk -F"'" '/define.*GLPI_VAR_DIR/{print$(NF-1)}' $GLPI_CONFIG_DIR/local_define.php)
export GLPI_LOG_DIR=$(awk -F"'" '/define.*GLPI_LOG_DIR/{print$(NF-1)}' $GLPI_CONFIG_DIR/local_define.php)
export GLPI_VERSION=$(awk -F"'" '/GLPI_VERSION.*[0-9].[0-9].[0-9]/{print$(NF-1)}' $GLPI_ROOT/inc/define.php)
export console=$GLPI_ROOT/bin/console
export phpVersion=$(php -r 'print PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
