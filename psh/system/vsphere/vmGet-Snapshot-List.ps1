$argc=$args.Count
$clusterName = $($args[0])
$days = $($args[1]).ToInt16()

$CutoffDate = (Get-Date).AddDays($day)

Get-Cluster "$clusterName" | Get-VM | Get-Snapshot | Where-Object { $_.Created -lt $CutoffDate } | Sort-Object `
@{Expression='SizeGB'; Descending=$true} , @{Expression='Created'; Descending=$false} | Format-Table `
@{Label='VM';Expression={$_.VM.Name}}, Name, @{Label='Created';Expression={$_.Created.ToString('yyyy-MM-dd HH:mm:ss')}},
@{Label='AgeDays';Expression={(New-TimeSpan $_.Created (Get-Date)).Days}},
@{Label='SizeGB';Expression={"{0,12:N3}" -f $_.SizeGB}} -AutoSize
