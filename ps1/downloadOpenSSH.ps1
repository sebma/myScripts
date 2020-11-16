$arch = (gwmi win32_processor).AddressWidth
$url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win"+$arch".zip"
$OutFile = basename "$url"
$sslTlsProtocols = [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, " + $sslTlsProtocols
wget -O "$OutFile" "$url"
[Net.ServicePointManager]::SecurityProtocol = $sslTlsProtocols
new-alias -name unzip -value expand-archive
unzip "$OutFile"
cd $(basename $OutFile .zip)
cd $(basename $OutFile .zip)
echo 
