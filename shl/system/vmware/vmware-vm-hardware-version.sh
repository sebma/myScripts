#!/usr/bin/env bash

set -u

test $(id -u) == 0 && sudo="" || sudo=sudo

biosAddress=$($sudo dmidecode -t bios | awk '/BIOS Information/{section_found=1}/Address:/&&section_found{printf$2;exit}')
case $biosAddress in
	"0xE8480" ) echo "ESX 2.5" ;;
	"0xE7C70" ) echo "ESX 3.0" ;;
	"0xE7910" ) echo "ESX 3.5" ;;
	"0xE7910" ) echo "ESX 4"   ;;
	"0xEA550" ) echo "ESX 4U1" ;;
	"0xEA2E0" ) echo "ESX 4.1" ;;
	"0xE72C0" ) echo "ESX 5"   ;;
	"0xE9AB0" ) echo "ESX 5.1" ;;
	"0xEA0C0" ) echo "ESX 5.1 (older)" ;;
	"0xEA050" ) echo "ESX 5.5" ;;
	"0xE9A40" ) echo "ESX 6.0" ;;
	"0xEA580" ) echo "ESXi 6.5" ;;
	"0xEA520" ) echo "ESXi 6.7" ;;
	"0xEA490" ) echo "ESXi 6.7U2" ;;
	"0xEA480" ) echo "ESXi 7.0" ;;
	* ) echo "Unknown version for bios address:" $biosAddress;;
esac
