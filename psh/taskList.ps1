#schtasks | sls -n "^TaskName|N/A|=======" | Out-String -Stream | sls -Context 1,0 $(get-date).year
#Get-ScheduledTask | Get-ScheduledTaskInfo  | Sort-Object Nextruntime | select Taskname, LastRunTime, NextRunTime | Out-GridView
Get-ScheduledTask | Get-ScheduledTaskInfo  | Sort-Object Nextruntime | select Taskname, LastRunTime, NextRunTime
