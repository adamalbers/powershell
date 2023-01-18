#Run this from Exchange Shell. This returns Distribution List SMTP addresses.
#If RequireSenderAuthentication is False then it's a public/external distribution group.
Get-DistributionGroup -ResultSize Unlimited | Select-Object DisplayName, PrimarySmtpAddress, RequireSenderAuthenticationEnabled | Sort-Object DisplayName | Format-Table -Auto

Exit 0