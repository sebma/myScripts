function service_info {
	$serviceName = $args[0]
	"=> serviceName = $serviceName :"
	Get-CimInstance win32_service | ? Name -eq $serviceName | Select Name , InstallDate , State , ServiceType , StartMode , ErrorControl , PathName , TagId , Caption , StartName , DelayedAutoStart
}

service_info @args
