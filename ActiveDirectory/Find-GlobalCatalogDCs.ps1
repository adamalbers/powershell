Import-Module ActiveDirectory
Get-ADDomainController -Filter * | Select-Object HostName,IsGlobalCatalog | Format-Table -Auto