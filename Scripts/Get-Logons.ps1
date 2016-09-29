<#
.SYNOPSIS
    Get interactive logon types
.NOTE
    Author: Adam Albers
#>

# Report file path
$reportPath = "$Env:SystemDrive/AMP/Reports/UserLogons-$(Get-Date -f yyyy-MM-dd).txt"

# Create column headings
$tableFormat = @{Expression={$_.TimeCreated};Label="Logon Time"},@{Expression={$_.Properties[5].Value};Label="User"},@{Expression={$_.Properties[8].Value};Label="Logon Type"},@{Expression={$_.Properties[18].Value};Label="Source IP Address"}

Get-WinEvent -FilterHashTable @{LogName='Security'; id=4624} | Where-Object {($_.Properties[8].Value -eq 2) -or ($_.Properties[8].Value -eq 10)} | Format-Table $tableFormat -AutoSize -Wrap | Out-File $reportPath
