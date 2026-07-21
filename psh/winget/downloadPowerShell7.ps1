# https://aka.ms/PowerShell-Release?release=v7.6.4
$PS7DirectDownloadURL = "https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.6.4-win-x64.msi"
$downloadedFile = $PS7DirectDownloadURL.split('/')[-1]
Invoke-WebRequest $PS7DirectDownloadURL -OutFile $downloadedFile
echo "=> downloadedFile = $downloadedFile"
