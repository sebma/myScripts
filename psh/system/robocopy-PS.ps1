$scriptName = Split-Path -Leaf $PSCommandPath
function robocopyPS {
	$argc=$args.Count
	if ( $argc -lt 2 ) {
		write-warning "Usage:$scriptName sourceDIR destinationDIR"
		exit 1
	}

	$sourceDIR = $args[0]
	$destinationDIR = Join-Path $args[1] $sourceDIR.Split('\')[-1]
	$robocopyOption = "/COPY:DATSO"
	$robocopyMirror = "/MIR"
	#$robocopyDryRUN = "/L"
	$logDIR = "C:\TEMP\Robocopy\Logs"

	gci $sourceDIR | foreach {
		$logFile = "$logDIR\$($_.BaseName).log"
		Write-Host robocopy $_.FullName $destinationDIR $robocopyDryRUN $robocopyOption $robocopyMirror /r:0 /np /v /log+:$logFile
		robocopy $_.FullName $destinationDIR $robocopyDryRUN $robocopyOption $robocopyMirror /r:0 /np /v /log+:$logFile
	}
}

robocopyPS @args
