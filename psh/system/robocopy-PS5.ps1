$scriptName = Split-Path -Leaf $PSCommandPath
function robocopyPS {
	$dirSep = [io.path]::DirectorySeparatorChar
	$argc=$args.Count
	if ( $argc -lt 2 ) {
		write-warning "Usage:$scriptName sourceDIR destinationDIR"
		exit 1
	}

	$sourceDIR = $args[0]
	$destinationDIR = $args[1]
	$sourceBaseName = $sourceDIR.Split($dirSep)[-1]
	$destinationDIR += $dirSep + $sourceBaseName
	$logDIR = "C:\TEMP\Robocopy\Logs"
	$logFile = $logDIR + $dirSep + $sourceBaseName + '.log'
	$nbThreads = $(Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
	$robocopyOptions = "/MT:$nbThreads /MIR /r:0 /np /v /tee"
	$fullSynchroFile = $destinationDIR + $dirSep + $sourceBaseName + ".synchro"
	$fullSynchro = Test-Path $fullSynchroFile

	if ( $fullSynchro ) {
		# Hide $fullSynchro file
		$(Get-ItemProperty $fullSynchro).Attributes = $(Get-ItemProperty $fullSynchro).Attributes -bor [io.fileattributes]::Hidden
		$robocopyOptions += " /COPY:DATSO"
	} else {
		$robocopyOptions += " /COPY:DAT"
	}

	#$robocopyDryRUN = "/L"
	$robocopyOptions = $robocopyOptions -split '\s+'

	gci $sourceDIR | foreach {
		Write-Host robocopy $_.FullName $destinationDIR $robocopyDryRUN @robocopyOptions /log+:$logFile
		robocopy $_.FullName $destinationDIR $robocopyDryRUN @robocopyOptions /log+:$logFile
	}

	if ( $fullSynchro ) { Remove-Item -Force $fullSynchroFile }
}

robocopyPS @args
