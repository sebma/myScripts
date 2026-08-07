#!/usr/bin/env pwsh
# vim: ft=powershell noet:
$scriptName = Split-Path -Leaf $PSCommandPath
function robocopyPS {
	$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$dirSep = [io.path]::DirectorySeparatorChar
	$argc=$args.Count
	if ( $argc -lt 2 ) {
		write-warning "Usage:$scriptName sourceDIR destinationDIR"
		exit 1
	}

	$sourceDIR = $args[0]
	$destinationDIR = $args[1]
	$nbThreads = $(Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
	$robocopyOptions = "/MT:$nbThreads /MIR /r:0 /np /v"

	$sourceBaseName = $sourceDIR.Split($dirSep)[-1]
	$destinationDIR += $dirSep + $sourceBaseName
	$logDIR = "C:\TEMP\Robocopy\Logs"
	$logFile = $logDIR + $dirSep + $sourceBaseName + '.log'
	$robocopyOptions += " /log+:$logFile"
	#$robocopyOptions += " /tee" # pour tout voir a l_ecran
	#$robocopyDryRUN = "/L"

	$fullSynchroFile = $destinationDIR + $dirSep + $sourceBaseName + ".synchro"
	$fullSynchro = Test-Path $fullSynchroFile
	if ( $fullSynchro ) {
		# Hide $fullSynchro file
		$(Get-ItemProperty $fullSynchro).Attributes = $(Get-ItemProperty $fullSynchro).Attributes -bor [io.fileattributes]::Hidden
		$robocopyOptions += " /COPY:DATSO"
	} else {
		$robocopyOptions += " /COPY:DAT"
	}

	$robocopyOptions = $robocopyOptions -split '\s+' # convertit les options de robocopy en array
	gci -Force $sourceDIR | foreach {
		Write-Host robocopy $_.FullName $destinationDIR\$_ $robocopyDryRUN @robocopyOptions
		Write-Host ""
		robocopy $_.FullName $destinationDIR\$_ $robocopyDryRUN @robocopyOptions
	}

	if ( $fullSynchro ) { Remove-Item -Force $fullSynchro }
	$stopwatch.Stop()
	$duration = $stopwatch.Elapsed
	Write-Host ""
	Write-Host "=> Execution time: $duration."
}

robocopyPS @args
