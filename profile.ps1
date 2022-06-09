#Requires -Version 2.0

<#
.SYNOPSIS
    Basic PowerShell profile.
.DESCRIPTION
    Standard PowerShell profile deployed to servers.
.NOTES
    File Name  : profile.ps1
    Author     : Adam Albers
.LINK
    https://github.com/adamalbers
    https://blogs.technet.microsoft.com/heyscriptingguy/2013/01/04/understanding-and-using-powershell-profiles/
#>

# Useful Functions

# Get the last boot time. More accurate than the uptime number in Resource Monitor.
Function uptime {
  Get-WmiObject Win32_OperatingSystem | Select-Object @{LABEL = 'Computer'; EXPRESSION = { $_.CSName } }, @{LABEL = 'LastBootUpTime'; EXPRESSION = { $_.ConverttoDateTime($_.LastBootUpTime) } }
}

# Settings specific to running as admin
# Post a warning about running as admin.
& {
  $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
  $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
  $IsAdmin = $prp.IsInRole($adm)
  If ($IsAdmin) {
    Write-Host "RUNNING AS ADMIN. USE CAUTION." -ForegroundColor "Red"
  }
}

# Show uptime before prompt
uptime
