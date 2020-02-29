<#
.SYNOPSIS
	Get sizes of each database for all SQL instances on localhost
.NOTES
	Author: Adam Albers
#>
# Event log settings to use for custom events
# You must have already created your custom event log and sources.
# That is outside the scope of this script.
$logName = "AMPSystems"
$eventSource = "AMP SQL Report"
$eventIDInfo = "1100"
$eventIDError = "1101"
$entryType = "Information"

# The task category is 99.99% of the time going to be 0 for "none." If you don't set this, you get complaints from the event log about not having custom categories defined.
$category = 0

# Report file path
$reportPath = "$Env:SystemDrive/AMP/Reports/SQLDatabases-$(Get-Date -f yyyy-MM-dd).txt"

# Load SQL assembly
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null

# Create array to hold database objects
$myDatabases = @()

# Create variable to hold event messages
$message = ""

ForEach ($Instance in (Get-WmiObject -Class Win32_Service -ComputerName $Env:ComputerName | Where-Object {$_.Name -like 'MSSQL$*'}))
{
	If ($Instance -eq $null){break}
        # Connect to SQL
        $InstanceString = "{0}\{1}" -f $Env:ComputerName, $Instance.Name.Split('$')[1]
        $Sql = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $InstanceString

        # Gather information
        ForEach ($Database in $Sql.Databases)
        {
	        $currentDatabase = "" | Select-Object Instance, Database, DatabaseSizeGB, SizeLimit
       		$currentDatabase.Instance = $InstanceString
        	$currentDatabase.Database = $Database.Name
        	$currentDatabase.DatabaseSizeGB = [Math]::Round($Database.Size/1024,2)
        	
		# Check for SQL Express Limitations
		# List SizeLimit as % of limit (4GB per database for SQL Express 2008 and earlier,
		# 10GB for 2008R2 and later)
		If ($Sql.Edition -like "*Express*")
		{
			If ($Sql.Version -lt 10.5) {$currentDatabase.SizeLimit = "{0:P}" -f ($currentDatabase.DatabaseSizeGB / 4)}
			Else {$currentDatabase.SizeLimit = "{0:P2}" -f ($currentDatabase.DatabaseSizeGB / 10)}
			
			If ($currentDatabase.SizeLimit -gt 80)
			{
			$entryType = "Error"
			$message = "$($currentDatabase.Database | Out-String) is at $($currentDatabase.SizeLimit | Out-String) of maximum size"
			Write-EventLog -LogName $logName -Source $eventSource -EventID $eventIDError -EntryType $entryType -Message $message -Category $category
			}
		}

		$myDatabases += $currentDatabase
        }

        # Cleanup
        Clear-Variable Sql -ErrorAction SilentlyContinue
        Clear-Variable InstanceString -ErrorAction SilentlyContinue
}
$myDatabases | Out-File $reportPath
$message = Get-Content $reportPath | Format-Table -AutoSize | Out-String
Write-EventLog -LogName $logName -Source $eventSource -EventID $eventIDInfo -EntryType "Information" -Message $message -Category $category