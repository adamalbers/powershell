Import-Module $env:SyncroModule

# Finds the disconnected sessions on a computer and logs them off.
# This script is intended to be run manually to kick disconnected users from a computer.
# 
# THIS MAKES NO ACCOUNT FOR IDLE TIME. IF THEY HAVE BEEN DISCONNECTED FOR 1 SECOND, THEY WILL BE LOGGED OFF.

<#
This $users query is convoluted because we have to parse raw text output from a non-PowerShell command.
The -split '\n' breaks each line into its own object so we then have an array of lines.

Disconnected sessions do not have session names so we replace a bunch of spaces with 'n/a' via the -replace '\s{18,}', '  n/a  ' piece.

The -replace '\s{2,}', ',' piece replaces 2 or more spaces with a comman so the fields can be converted to CSV. We do 2 or more because the first line headers 'LOGON TIME' and 'IDLE TIME' include a space and we don't want those to be split.
#>

# Get all user sessions
$users = (query user) -split '\n' -replace '\s{18,}', '  n/a  ' -replace '\s{2,}', ',' | ConvertFrom-Csv

# Get active user sessions
$activeUsers = $users | Where-Object { $_.State -eq 'Active' }

# Find and list the idle user sessions
$disconnectedUsers = $users | Where-Object { $_.State -eq 'Disc' }

Write-Output 'Found these active sessions:'
Write-Output "$activeUsers"


Write-Output 'Attempting to logoff these disconnected sessions:'
Write-Output "$disconnectedUsers"

Log-Activity -Message "Logged off $disconnectedUsers" -EventName 'Logoff Disconnected Users'

# Loop through the disconnected user sessions and log them off
$disconnectedUsers | ForEach-Object {
    logoff $($_.Id)
}

Exit 0