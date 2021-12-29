#This will return the last reboot time and the user that initiated it.
Get-EventLog -Log System | Where-Object {$_.EventID –eq '1074'} | Format-Table MachineName, Username, TimeGenerated –AutoSize
