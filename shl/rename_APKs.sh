#!/usr/bin/env bash

function renameAPK {
	type aapt || return
	for package
	do
		echo "=> package = $package"
		[ -f "$package" ] || {
			echo "==> ERROR : The package $package does not exist." >&2; continue
		}

		packagePath=$(dirname $package)
		packageID=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$2}')
		packageVersion=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$6}' | cut -d' ' -f1)
		packageNewFileName="$packagePath/$packageID-$packageVersion.apk"
		[ "$package" = $packageNewFileName ] || mv -v "$package" $packageNewFileName
	done
}

renameAPK $@
