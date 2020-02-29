Import-Module ActiveDirectory
$reportPath = "$Env:SystemDrive\AMP\Reports\oldUsers-$(Get-Date -f yyyy-MM-dd).csv"
$date=(Get-Date).AddDays(-60)

Get-ADUser -Property Name,samAccountName,lastLogonDate -Filter {(lastLogonDate -lt $date) -and (Enabled -eq $true)} | Sort-Object samAccountName | Select-Object Name,samAccountName,lastLogonDate | Export-CSV $reportPath -NoTypeInformation