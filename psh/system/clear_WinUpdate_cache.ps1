Stop-Service wuauserv
rm -force -r $env:WINDIR/SoftwareDistribution/Download/*
Start-Service wuauserv
