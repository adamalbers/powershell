Import-Module ActiveDirectory

$date=(Get-Date).AddDays(-60)

Get-ADComputer -Property Name,lastLogonDate -Filter {lastLogonDate -lt $date} | Format-Table Name,lastLogonDate -Wrap
