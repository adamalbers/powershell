Import-Module ActiveDirectory
$reportPath = "$Env:SystemDrive\AMP\Reports\oldComputers-$(Get-Date -f yyyy-MM-dd).csv"
$date=(Get-Date).AddDays(-60)

Get-ADComputer -Property Name,lastLogonDate -Filter {(lastLogonDate -lt $date) -and (Enabled -eq $true)} | Sort-Object Name | Select-Object Name,LastLogonDate | Export-CSV $reportPath -NoTypeInformation