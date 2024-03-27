$myPattern = '*'+$args[0]+'*'
Get-ADGroup -Properties CanonicalName , Created , Description -Filter { name -like $myPattern }
