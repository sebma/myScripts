$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
Get-ADGroup -Properties CanonicalName , Created , Description -Filter { name -like $myPattern }
