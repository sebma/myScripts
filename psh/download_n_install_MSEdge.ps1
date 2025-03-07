md $env:temp\edgeinstall 2>$null
$Download = "$env:temp\edgeinstall\MicrosoftEdgeEnterpriseX64.msi"
if ( test-path ENV:HTTP_PROXY ) {
        Invoke-WebRequest 'http://go.microsoft.com/fwlink/?LinkID=2093437'  -OutFile $Download -proxy $ENV:HTTP_PROXY
} else {
        Invoke-WebRequest 'http://go.microsoft.com/fwlink/?LinkID=2093437'  -OutFile $Download
}
ls $Download
Start-Process "$Download" -ArgumentList "/quiet"
