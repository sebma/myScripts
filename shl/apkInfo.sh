#!/usr/bin/env bash

function apkInfo { 
	for package
	do
		echo "=> package = $package"
		[ -f "$package" ] || {
			echo "==> ERROR : The file $package does not exist." >&2; continue
		}
		aapt dump badging "$package" | awk -F"'" '/^package:/{print$(NF-1)}/application:|^package:/{print$2}/[Ss]dkVersion:/'
	done
}

apkInfo $@
