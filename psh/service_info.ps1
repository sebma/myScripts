function service_info {
	$ErrorActionPreference = 'Stop'
	$argc=$args.Count
	if ( $argc -gt 0) {
		for($i=0;$i -lt $argc;$i++) {
			$serviceName = $($args[$i])
			echo "=> serviceName = <$serviceName> :`n"
			try {
				Get-Service $serviceName >$null 2>&1
				Get-CimInstance win32_service | ? Name -eq $serviceName | Select Name , Caption , State , ServiceType , StartMode , ErrorControl , PathName , TagId , StartName , DelayedAutoStart
			} catch {
				echo "=> WARNING: The service <$serviceName> does not exist."
			}
		}
	}
}

service_info @args
