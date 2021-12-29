$ErrorActionPreference = "SilentlyContinue"

# Enter the number of days of log files to keep here
$daysToKeep = 3

# Add folders to be cleaned
$foldersToClean = @("$Env:SystemDrive\Windows\SoftwareDistribution\*",
                    "$Env:SystemDrive\Windows\Temp\*",
                    "$Env:SystemDrive\Users\*\AppData\Local\Temp\*",
                    "$Env:SystemDrive\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*",
                    "$Env:SystemDrive\inetpub\logs\LogFiles\*")

function diskSize {
    Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName, @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, @{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, @{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } | Format-Table -AutoSize | Out-String
}

$sizeBefore = diskSize                    
Write-Output "Size Before Cleaning: $sizeBefore"
                    
# Stops the windows update service for cleaning SoftwareDistribution folder.
Get-Service -Name wuauserv | Stop-Service -Force

# Delete files older than $daysToKeep in $foldersToClean
Get-ChildItem -Path $foldersToClean -Recurse -Force | Where-Object { ($_.LastWriteTime -lt $(Get-Date).AddDays(-$daysToKeep)) } | Remove-Item -Force -Recurse -Confirm:$false    

$sizeAfter =  diskSize
Write-Output "Size After Cleaning: $sizeAfter"

# Restart the Windows Update Service
Get-Service -Name wuauserv | Start-Service

Exit 0