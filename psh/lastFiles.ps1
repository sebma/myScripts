ls -file -Recurse | ? { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } | % FullName
