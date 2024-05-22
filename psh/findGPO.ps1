$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
get-gpo -all | ? DisplayName -like $myPattern
