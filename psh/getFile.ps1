#!/usr/bin/env pwsh
Set-PSDebug -Trace 1
$url="$1"
$OutFile=basename "$url"
$sslTlsProtocols = [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, " + $sslTlsProtocols
iwr -O "$OutFile" "$url"
[Net.ServicePointManager]::SecurityProtocol = $sslTlsProtocols
