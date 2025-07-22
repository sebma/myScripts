function coutdated { choco outdated @args }
function cfind { choco find @args }
function chome { Start-Process $(choco info @args | sls "Site:").Line.Split()[-1] }
function cinfo { choco info @args }
Set-Variable -Scope global shimgen "$env:ChocolateyInstall\tools\shimgen.exe"
