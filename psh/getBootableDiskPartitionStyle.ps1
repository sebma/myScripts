(Get-Disk | Where { $_.IsBoot -eq $TRUE } ).PartitionStyle
