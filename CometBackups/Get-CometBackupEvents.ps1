$csvPath = "C:\Example\cometBackupEvents.csv"

# Uncomment one of these based on scanning all computers or just the servers.
#$computers = Get-ADComputer -Filter 'Enabled -eq "true"' -Properties Name
$computers = Get-ADComputer -Filter 'Enabled -eq "true" -and OperatingSystem -like "*Server*"' -Properties Name

Invoke-Command -ComputerName $($computers.Name) -ScriptBlock { Get-WinEvent -LogName Application | Where-Object { $_.ProviderName -match 'backup-tool' } | Select-Object TimeCreated, MachineName, LogName, ProviderName, Id, LevelDisplayName, Message } -ErrorAction SilentlyContinue | Export-Csv -Path "$csvPath" -NoTypeInformation -Append

Exit 0