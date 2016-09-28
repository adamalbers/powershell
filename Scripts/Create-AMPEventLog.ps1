# Create custom event log in Windows for storing AMP events
# These events can be used for custom alerts in the RMM

# Create only if log doesn't already exist
If (!(Get-EventLog "AMPSystems"))
{
    New-EventLog -LogName "AMPSystems" -Source "AMPSystems"
    # The log doesn't actually exist so we create our first event here
    Write-EventLog -LogName "AMPSystems" -Source "AMPSystems" -Message "AMPSystems event log created $(Get-Date -f yyyy-MM-dd)" -EventID 001 -EntryType Information
}
