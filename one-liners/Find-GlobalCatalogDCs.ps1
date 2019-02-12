#Make sure you run this with the Active Directory module.
Get-ADDomainController -Filter * | Select HostName,IsGlobalCatalog | Format-Table -Auto
