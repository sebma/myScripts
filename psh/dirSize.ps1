#!/usr/bin/env pwsh
# vim: ft=powershell noet:
function dirSize2iec {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$size = $args[0]
	$size2IEC = ""
	switch( $size ) {
		{ $_ -ge 1pb -and $_ -le 1024pb } { $size2IEC = "{0:n2} TiB" -f ( $size / 1pb ); break }
		{ $_ -ge 1tb -and $_ -le 1pb } { $size2IEC = "{0:n2} TiB" -f ( $size / 1tb ); break }
		{ $_ -ge 1gb -and $_ -le 1tb } { $size2IEC = "{0:n2} GiB" -f ( $size / 1gb ); break }
		{ $_ -ge 1mb -and $_ -le 1gb } { $size2IEC = "{0:n2} MiB" -f ( $size / 1mb ); break }
		{ $_ -ge 1kb -and $_ -le 1mb } { $size2IEC = "{0:n2} KiB" -f ( $size / 1kb ); break }
		{ $_ -ge 0   -and $_ -le 1kb } { $size2IEC = "{0:n2} B  " -f   $size; break }
	}

	#Write-Host "=> Ending of <$FUNCNAME> function ..."
	return $size2IEC
}

function dirSize {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$dirName = $args[0]
	$size = [uint64]( dir "$dirName" -force -recurse 2>$null | measure -property length -sum ).Sum

	#Write-Host "=> Ending of <$FUNCNAME> function ..."
	return [uint64]$size
}

function time {
	$duration = ( "$args" | Measure-Command { Invoke-Expression $_ | Out-Default } ).toString("hh\:mm\:ss\.ff")
	"`n$duration`n"
}

function main {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$argc = $args.Count
	#$total = 0
	if ( $argc ) {
		foreach ($dir in $args) {
			$argc = $dir.Count
			foreach ($d in $dir) {
				$dir = $d
				if ( ! ( Test-Path $dir ) ) { Write-Host "=> The $dir directory does not exits.";continue; }
				$size = $( dirSize $dir )[-1]
				$total += $size
				Write-Host "=> dir = < $dir >"
				Write-Host "=> size = $size"
				$size2iec = dirSize2iec($size)
				Write-Host "=> dirSize2iec(size) = $size2iec."
				Write-Host ""
			}
		}
	} else {
		$dir = "."
		$total = $( dirSize $dir )[-1]
		Write-Host "=> dir = < $dir >"
	}

	if ( $argc -eq 0 -or $argc -ge 2 ) {
		Write-Host "=> total = $total"
		$size2iec = dirSize2iec($total)
		Write-Host "=> dirSize2iec(total) = $size2iec."
		Write-Host ""
	}
	#Write-Host "=> Ending of <$FUNCNAME> function ..."
}

main @args
