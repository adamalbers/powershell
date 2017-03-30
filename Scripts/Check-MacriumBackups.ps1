<#
.SYNOPSIS
    Check Macrium (v5+) event logs time since last successful backup
.DESCRIPTION
     Check Macrium Reflect/Operational log for absence of success events, indicating job did not run or other non-failure issue such as job is stuck.
.NOTES
    Author: Adam Albers
#>

# Declare variables

$currentDate = Get-Date
$pastDueDate = (Get-Date).AddHours(-24)
$logName = "Macrium Reflect/Operational"
$eventID = 278
$backupOverdue = $false

$lastSuccessEvent = Get-WinEvent -FilterHashtable @{LogName=$logName;ID=$eventID} -MaxEvents 1

If ($lastSuccessEvent.TimeCreated -lt $pastDueDate)
{
    $backupOverdue = $true
}

Write-Output $backupOverdue
Exit