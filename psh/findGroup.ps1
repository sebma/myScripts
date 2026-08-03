$myRegExp = $args[0]
$DC = $env:LOGONSERVER.Substring(2)
Get-ADGroup -Server $DC -Properties CN , CanonicalName , Created, Modified , Description -Filter '*' | ? Name -iMatch $myRegExp
