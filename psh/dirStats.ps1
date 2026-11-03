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
	$sizeOnDisk = 0L

	$driveLetter = (Get-Item (Resolve-Path $dirName)).PSDrive.Name + ':'
	$clusterSize = (Get-CimInstance Win32_Volume -Filter "DriveLetter='$driveLetter'").BlockSize
	if ( ! $clusterSize ) { $clusterSize = 4096 }

	$items = dir "$dirName" -force -recurse 2>$null

	foreach($item in $items) {
		if($item.PSIsContainer) {
			$dirs++
		}
		else {
			$files++
			$size += $item.Length
			$sizeOnDisk += [uint64]([math]::Ceiling($item.Length / $clusterSize) * $clusterSize)
		}
	}

	#Write-Host "=> Ending of <$FUNCNAME> function ..."
	return $size , $sizeOnDisk , $files , $dirs
}

function time {
    param(
        [scriptblock]$ScriptBlock
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $sw.Stop()

    [PSCustomObject]@{
        Result   = $result
        Duration = $sw.Elapsed
    }
}

function main {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$ligneFeed = "`n"
	$argc = $args.Count
	$totalSize = 0L
	if ( $argc ) {
		foreach ($dirs in $args) {
			$argc = $dirs.Count
			foreach ($dir in $dirs) {
				if ( ! ( Test-Path $dir ) ) { Write-Host "=> The $dir directory does not exits.";continue; }
				Write-Host "=> dir = < $dir >"
				$dirStatsResult = time { dirStats $dir }
				$size , $sizeOnDisk , $nbFiles , $nbDirs = $dirStatsResult.Result
				$duration = $dirStatsResult.Duration
				$totalSize += $size
				$totalSizeOnDisk += $sizeOnDisk
				$totalFiles += $nbFiles
				$totalDirs += $nbDirs

				Write-Host "=> nbFiles = $nbFiles"
				Write-Host "=> nbDirs = $nbDirs"

				Write-Host "$ligneFeed=> size = $size"
				$iecSize = size2iec($size)
				Write-Host "=> size2iec(size) = $iecSize."

				Write-Host "$ligneFeed=> sizeOnDisk = $sizeOnDisk"
				$iecSizeOnDisk = size2iec($sizeOnDisk)
				Write-Host "=> size2iec(sizeOnDisk) = $iecSizeOnDisk."
				Write-Host "$ligneFeed=> duration = $($duration.ToString('hh\:mm\:ss\.ff'))`n"
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
		$iecSizeOnDisk = size2iec($totalSizeOnDisk)
		Write-Host "=> size2iec(totalSizeOnDisk) = $iecSizeOnDisk."
		Write-Host ""
	}
	#Write-Host "=> Ending of <$FUNCNAME> function ..."
}

main @args
