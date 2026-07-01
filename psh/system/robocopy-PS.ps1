$scriptName = Split-Path -Leaf $PSCommandPath
function robocopyPS {
	$argc=$args.Count
	if ( $argc -lt 2 ) {
		write-warning "Usage:$scriptName sourceDIR destinationDIR"
		exit 1
	}

	$sourceDIR = $args[0]
	$destinationDIR = $args[1]
	$sourceBaseName = $sourceDIR.Split('\')[-1]
	$destinationDIR = Join-Path $destinationDIR $sourceBaseName
	$logDIR = "C:\TEMP\Robocopy\Logs"
#	$logFile = $logDIR + '\' + $sourceBaseName + '.log'
	$robocopyOptions = "/COPY:DATSO /MIR /r:0 /np /v /tee" -split '\s+'
	#$robocopyDryRUN = "/L"

	gci $sourceDIR | foreach {
		$logFile = $logDIR + '\' + $sourceBaseName + '.log'
		Write-Host robocopy $_.FullName $destinationDIR $robocopyDryRUN @robocopyOptions /log+:$logFile
		robocopy $_.FullName $destinationDIR $robocopyDryRUN @robocopyOptions /log+:$logFile
	}
}

robocopyPS @args
