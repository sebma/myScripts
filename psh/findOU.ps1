$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
Get-ADOrganizationalUnit -Properties CanonicalName -Filter { Name -like $myPattern }
