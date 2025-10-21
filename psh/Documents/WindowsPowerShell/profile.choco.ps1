"=> Sourcing Chocolatey functions ..."
$global:shimgen = "$env:ChocolateyInstall\tools\shimgen.exe"
function cfind { choco find @args }
function chome { Start-Process $(choco info @args | sls "Site:").Line.Split()[-1] }
function cinfo { choco info @args }
function clistlocal { choco list -l @args | sort }
function coutdated { choco outdated @args }
function csearch { choco search @args | sort }
function cversion { choco info @args | sls "^$($args[0])" }
