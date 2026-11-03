$subjectRegExp = $args[0]
ls Cert:\ -R | ? { $_.PSIsContainer -eq $false -and $_.Subject -imatch $subjectRegExp } | Select Subject, Issuer , NotBefore, NotAfter, PSParentPath, Thumbprint
