<#
.SYNOPSIS
	Create custom event log
.DESCRIPTION
	This script generates a custom event log under Windows Event Viewer.
	Simply change the $logName variable to whatever you desire -- no spaces or special characters.
.NOTES
	Author: Adam Albers
#>
# Name your log
$logName = "AMPSystems"
$eventSources = @("AMP Systems","AMP SQL Report","AMP Backup Report")

# Create the log
New-EventLog -LogName $logName -Source $eventSources
# The log doesn't actually exist until we create our first event here
Write-EventLog -LogName $logName -Source $eventSources[0] -Message "$logName event log created $(Get-Date -f yyyy-MM-dd)" -EventID 001 -EntryType Information