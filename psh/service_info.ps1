function service_info {
	$ErrorActionPreference = 'Stop'
	$argc=$args.Count
	if ( $argc -gt 0) {
		for($i=0;$i -lt $argc;$i++) {
			$serviceName = $($args[$i])
			"=> serviceName = <$serviceName> :"
			try {
				Get-Service $serviceName 2>$null
				Get-CimInstance win32_service | ? Name -eq $serviceName | Select Name , InstallDate , State , ServiceType , StartMode , ErrorControl , PathName , TagId , Caption , StartName , DelayedAutoStart
			} catch {
				echo "=> WARNING: The service <$serviceName> does not exist."
			}
		}
	}
}

service_info @args
