# Get sizes of each individual database for all SQL instances on the computer

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null

$myDatabases = @()

ForEach ($Instance in (Get-WmiObject -Class Win32_Service -ComputerName $Env:ComputerName | Where {$_.Name -like 'MSSQL$*'}))
{
	If ($Instance -eq $null){break}
        # Connect to SQL
        $InstanceString = "{0}\{1}" -f $Env:ComputerName, $Instance.Name.Split('$')[1]
        $Sql = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $InstanceString

        # Gather information
        ForEach ($Database in $Sql.Databases)
        {
	        $currentDatabase = "" | Select Instance, Database, DatabaseSizeGB, SizeLimit
       		$currentDatabase.Instance = $InstanceString
        	$currentDatabase.Database = $Database.Name
        	$currentDatabase.DatabaseSizeGB = [Math]::Round($Database.Size/1024,2)
        	
		#Check for SQL Express Limitations
		# List SizeLimit as % of limit (4GB per database for SQL Express 2008 and earlier,
		# 10GB for 2008R2 and later)
		If ($Sql.Edition -like "*Express*")
		{
			If ($Sql.Version -lt "10.5") {$currentDatabase.SizeLimit = "{0:P}" -f ($currentDatabase.DatabaseSizeGB / 4)}
			Else {$currentDatabase.SizeLimit = "{0:P}" -f ($currentDatabase.DatabaseSizeGB / 10)}
		}

		$myDatabases += $currentDatabase
        }

        # Cleanup
        Clear-Variable Sql -ErrorAction SilentlyContinue
        Clear-Variable InstanceString -ErrorAction SilentlyContinue
}

$myDatabases | Out-File $Env:SystemDrive/AMP/Reports/SQLdatabases-$(Get-Date -f yyyy-MM-dd).txt
