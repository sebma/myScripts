ls -File -R | ? { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } | % FullName
