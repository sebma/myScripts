#!/usr/bin/env pwsh
# vim: ft=powershell noet:
function size2iec {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$size = $args[0]
	$iecSize = ""
	switch( $size ) {
		{ $_ -ge 1pb -and $_ -le 1024pb } { $iecSize = "{0:n2} TiB" -f ( $size / 1pb ); break }
		{ $_ -ge 1tb -and $_ -le 1pb } { $iecSize = "{0:n2} TiB" -f ( $size / 1tb ); break }
		{ $_ -ge 1gb -and $_ -le 1tb } { $iecSize = "{0:n2} GiB" -f ( $size / 1gb ); break }
		{ $_ -ge 1mb -and $_ -le 1gb } { $iecSize = "{0:n2} MiB" -f ( $size / 1mb ); break }
		{ $_ -ge 1kb -and $_ -le 1mb } { $iecSize = "{0:n2} KiB" -f ( $size / 1kb ); break }
		{ $_ -ge 0   -and $_ -le 1kb } { $iecSize = "{0:n2} B  " -f   $size; break }
	}

	#Write-Host "=> Ending of <$FUNCNAME> function ..."
	return $iecSize
}

function dirStats {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$dirName = $args[0]

	$files = 0L
	$dirs = 0L
	$size = 0L

	$items = dir "$dirName" -force -recurse 2>$null

	foreach($item in $items) {
		if($item.PSIsContainer) {
			$dirs++
		}
		else {
			$files++
			$size += $item.Length
		}
	}

	#Write-Host "=> Ending of <$FUNCNAME> function ..."
	return $size , $files , $dirs
}

function time {
	$duration = ( "$args" | Measure-Command { Invoke-Expression $_ | Out-Default } ).toString("hh\:mm\:ss\.ff")
	"`n$duration`n"
}

function main {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$argc = $args.Count
	$totalSize = 0L
	if ( $argc ) {
		foreach ($dirs in $args) {
			$argc = $dirs.Count
			foreach ($dir in $dirs) {
				if ( ! ( Test-Path $dir ) ) { Write-Host "=> The $dir directory does not exits.";continue; }
				Write-Host "=> dir = < $dir >"
				$size , $nbFiles , $nbDirs = $( dirStats $dir )
				$totalSize += $size
				$totalFiles += $nbFiles
				$totalDirs += $nbDirs
				Write-Host "=> nbFiles = $nbFiles"
				Write-Host "=> nbDirs = $nbDirs"
				Write-Host "=> size = $size"
				$iecSize = size2iec($size)
				Write-Host "=> size2iec(size) = $iecSize."
				Write-Host ""
			}
		}
	} else {
		$dir = "."
		$totalSize = $( dirStats $dir )[-1]
		Write-Host "=> dir = < $dir >"
	}

	if ( $argc -eq 0 -or $argc -ge 2 ) {
		Write-Host "=> totalFiles = $totalFiles"
		Write-Host "=> totalFiles = $totalDirs"
		Write-Host "=> totalSize = $totalSize"
		$iecSize = size2iec($totalSize)
		Write-Host "=> size2iec(totalSize) = $iecSize."
		Write-Host ""
	}
	#Write-Host "=> Ending of <$FUNCNAME> function ..."
}

main @args
