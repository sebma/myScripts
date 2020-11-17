# Whatever
Set-PSDebug -Trace 1
$arch = (gwmi win32_processor).AddressWidth
openSSHLatestVersion = "v8.1.0.0p1-Beta"
$url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/"+$openSSHLatestVersion+"/OpenSSH-Win"+$arch".zip"
$OutFile = basename "$url"
$sslTlsProtocols = [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, " + $sslTlsProtocols
iwr -O "$OutFile" "$url"
[Net.ServicePointManager]::SecurityProtocol = $sslTlsProtocols
new-alias -name unzip -value expand-archive
unzip "$OutFile"
cd $(basename $OutFile .zip)
cd $(basename $OutFile .zip)
echo "Please run ./install-sshd.ps1"
