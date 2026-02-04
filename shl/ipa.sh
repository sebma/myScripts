#!/usr/bin/env bash

function ipa {
	local interFace=$1
	ifconfig $interFace | awk -F ' ' '/^[a-z]+[0-9]?:?\s?/{sub(":","",$1);iface=$1};/inet /{sub(".*:","",$2);ip=$2;print iface"\t: "ip}'
}

ipa $1
