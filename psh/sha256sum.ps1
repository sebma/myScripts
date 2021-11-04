#!/usr/bin/env pwsh
param($filename)
function calcSignature() {
	$scriptName = Split-Path -Leaf $PSCommandPath
	switch( $scriptName ) {
		"md5sum.ps1" { $algo = "MD5"; Break }
		"sha1sum.ps1" { $algo = "SHA1"; Break }
		"sha256sum.ps1" { $algo = "SHA256"; Break }
		"sha384sum.ps1" { $algo = "SHA384"; Break }
		"sha512sum.ps1" { $algo = "SHA512"; Break }
	}
	(Get-FileHash -algo $algo $filename).Hash + "  " + $filename
}

calcSignature
