Import-Module ActiveDirectory

$startDate = (Get-Date 2021-01-01)
$reportPath = "$Env:Temp\hotfix-report.csv"
$computers = Get-ADComputer -Filter 'Enabled -eq "true"' -Properties * | Where-Object { $_.LastLogonDate -ge $startDate }

Invoke-Command -ComputerName $($computers.Name) -ScriptBlock { Get-HotFix | Where-Object { $_.InstalledOn -ge $startDate } | Sort-Object InstalledOn } -ErrorAction SilentlyContinue | Select-Object PSComputername, HotfixID, InstalledOn | Export-Csv -Path "$reportPath" -NoTypeInformation

Exit 0