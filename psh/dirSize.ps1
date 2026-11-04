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

function dirSize {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	#Write-Host "=> Starting <$FUNCNAME> function ..."

	$dirName = $args[0]
	$size = [uint64]0
	$sizeOnDisk = [uint64]0

	$driveLetter = (Get-Item (Resolve-Path $dirName)).PSDrive.Name + ':'
	$clusterSize = (Get-CimInstance Win32_Volume -Filter "DriveLetter='$driveLetter'").BlockSize
	if ( ! $clusterSize ) { $clusterSize = 4096 }

	@(dir $dirName -Force -Recurse -File 2>$null).ForEach({
		$size += $_.Length
		$sizeOnDisk += [uint64]([math]::Ceiling($_.Length / $clusterSize) * $clusterSize)
	})

	#Write-Host "=> Ending of <$FUNCNAME> function ..."
	return $size , $sizeOnDisk
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
	#$total = 0
	if ( $argc ) {
		foreach ($dirs in $args) {
			$argc = $dirs.Count
			foreach ($dir in $dirs) {
				if ( ! ( Test-Path $dir ) ) { Write-Host "=> The $dir directory does not exits.";continue; }
				Write-Host "=> dir = < $dir >"
				$dirSizeResult = time { dirSize $dir }
				$size , $sizeOnDisk = $dirSizeResult.Result
				$totalDuration += $dirSizeResult.Duration
				$total += $size
				$totalOnDisk += $sizeOnDisk
				$iecSize = size2iec($size)

				Write-Host "$ligneFeed=> size = $size"
				Write-Host "=> size2iec(size) = $iecSize."

				$iecSizeOnDisk = size2iec($sizeOnDisk)
				Write-Host "$ligneFeed=> sizeOnDisk = $sizeOnDisk"
				Write-Host "=> size2iec(sizeOnDisk) = $iecSizeOnDisk."
				Write-Host "$ligneFeed=> totalDuration = $($totalDuration.ToString('hh\:mm\:ss\.ff'))`n"
			}
		}
	} else {
		$dir = "."
		$total , $totalOnDisk = dirSize $dir
		Write-Host "=> dir = < $dir >"
	}

	if ( $argc -eq 0 -or $argc -ge 2 ) {
		Write-Host "=> total = $total"
		$iecSize = size2iec($total)
		Write-Host "=> size2iec(total) = $iecSize."
		$iecSizeOnDisk = size2iec($sizeOnDisk)
		Write-Host "=> size2iec(sizeOnDisk) = $iecSizeOnDisk."
		Write-Host ""
	}
	#Write-Host "=> Ending of <$FUNCNAME> function ..."
}

main @args
