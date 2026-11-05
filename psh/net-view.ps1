$smbServer = $args[0]
net view "\\$smbServer" | Select -Skip 7 | Select-String '^\S+' | ForEach-Object { ($_ -split '\s+')[0] }
