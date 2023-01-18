<#
.SYNOPSIS
    Check Macrium (v5+) event logs time since last success or failed backup
.DESCRIPTION
     Check Macrium Reflect/Operational log for absence of success or failure events, indicating job did not run or other non-failure issue such as job is stuck.
.NOTES
    Author: Adam Albers
#>

# Declare variables

$currentDate = Get-Date
$pastDueDate = (Get-Date).AddHours(-24)
$logName = 'Macrium Reflect/Operational'
$eventIDs = 278, 290
$backupOverdue = $false

$lastSuccessEvent = Get-WinEvent -FilterHashtable @{LogName = $logName; ID = $eventIDs } -MaxEvents 1

If ($lastSuccessEvent.TimeCreated -lt $pastDueDate) {
    $backupOverdue = $true
}

Write-Output $backupOverdue
Exit 0