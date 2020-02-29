Import-Module $env:SyncroModule

# Enter your Company information here:
$subdomain = "example"

$ticketDuration = 5  # This is the number of minutes you want added to the ticket

$daysToDelete = 7  # Enter the number of days of log files to keep here
$ErrorActionPreference = "SilentlyContinue"

$sizeBefore = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName, @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, @{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, @{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } | Format-Table -AutoSize | Out-String                      
                    
# Stops the windows update service. 
Get-Service -Name wuauserv | Stop-Service -Force -ErrorAction SilentlyContinue

# Deletes the contents of windows software distribution.
Get-ChildItem "$Env:SystemDrive\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.LastWriteTime -lt $(Get-Date).AddDays(-$daysToDelete)) } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue    

# Deletes the contents of the Windows Temp folder.
Get-ChildItem "$Env:Systemdrive\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.LastWriteTime -lt $(Get-Date).AddDays(-$daysToDelete)) } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
             
# Delets all files and folders in user's Temp folder. 
Get-ChildItem "$Env:Systemdrive\Users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.LastWriteTime -lt $(Get-Date).AddDays(-$daysToDelete))} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Remove all files and folders in user's Temporary Internet Files. 
Get-ChildItem "$Env:Systemdrive\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {($_.LastWriteTime -le $(Get-Date).AddDays(-$daysToDelete))} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    
# Cleans IIS Logs if applicable.
Get-ChildItem "$Env:Systemdrive\inetpub\logs\LogFiles\*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.LastWriteTime -le $(Get-Date).AddDays(-$daysToDelete)) } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

$sizeAfter =  Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName, @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, @{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, @{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } | Format-Table -AutoSize | Out-String

# Restart the Windows Update Service
Get-Service -Name wuauserv | Start-Service


# Create Ticket and get the ticket number
$syncroTicket = Create-Syncro-Ticket -Subdomain "$subdomain" -Subject "Cleanup for $Env:ComputerName" -IssueType "Other" -Status "New"
$ticket = $syncroTicket.ticket.number

$body = "Cleaned temporary files. `
            Free space before: $sizeBefore `
            Free space after: $sizeAfter"

# Add time to ticket
$startAt = (Get-Date).AddMinutes(-10).toString("o")
Create-Syncro-Ticket-TimerEntry -Subdomain "$subdomain" -TicketIdOrNumber $ticket -StartTime $startAt -DurationMinutes $ticketDuration -Notes "Cleanup of temporary files."

# Add ticket notes
Create-Syncro-Ticket-Comment -Subdomain "$subdomain" -TicketIdOrNumber $ticket -Subject "Temp File Cleanup for $Env:ComputerName" -Body "$body" -Hidden $False -DoNotEmail $True

#Close Ticket
Update-Syncro-Ticket -Subdomain "$subdomain" -TicketIdOrNumber $ticket -Status "Resolved"

Exit 0