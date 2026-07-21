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
	$sourceBaseName = $sourceDIR.Split('\')[-1]
	$destinationDIR =+ $dirSep + $sourceBaseName
	$logDIR = "C:\TEMP\Robocopy\Logs"
	$logFile = $logDIR + '\' + $sourceBaseName + '.log'
	$nbThreads = $(Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
	$robocopyOptions = "/MT:$nbThreads /MIR /r:0 /np /v /tee"
	$fullSynchro = $destinationDIR + $dirSep + $sourceBaseName + ".synchro"

	if ( Test-Path $fullSynchro ) { $robocopyOptions += " /COPY:DATSO" }
	else { $robocopyOptions += " /COPY:DAT" }
	$robocopyOptions = $robocopyOptions -split '\s+'
	#$robocopyDryRUN = "/L"

	gci $sourceDIR | foreach {
		Write-Host robocopy $_.FullName $destinationDIR $robocopyDryRUN @robocopyOptions /log+:$logFile
		robocopy $_.FullName $destinationDIR $robocopyDryRUN @robocopyOptions /log+:$logFile
	}

	if ( Test-Path $fullSynchro ) Remove-Item -Force $fullSynchro
}

robocopyPS @args
