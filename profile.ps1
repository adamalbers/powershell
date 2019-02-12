#Requires -Version 2.0

<#
.SYNOPSIS
    Basic PowerShell profile.
.DESCRIPTION
    Standard PowerShell profile deployed to servers. Ensures transcripts are kept
    to aid in post mortem troubleshooting. See links for description of the various
    places to save a PowerShell profile.
.NOTES
    File Name  : profile.ps1
    Author     : Adam Albers
.LINK
    https://github.com/adamalbers
    https://blogs.technet.microsoft.com/heyscriptingguy/2013/01/04/understanding-and-using-powershell-profiles/
#>

# Start at root of system drive
Set-Location -Path $Env:SystemDrive/

# Create the transcript directory if it does not exist
$transcriptPath = "$Env:SystemDrive/path/to/transcripts"

if (!(Test-Path $transcriptPath))
{
        New-Item $transcriptPath -Type Directory
}

# Start a transcript to record all activity in this PowerShell session
Start-Transcript -Path $transcriptPath/powershell-$(Get-Date -Format yyyy-MM-dd-HH.mm.ss).txt -Append

# Useful Functions

# Get the last boot time. More accurate than the uptime number in Resource Monitor.
Function uptime {
        Get-WmiObject Win32_OperatingSystem | Select-Object @{LABEL='Computer';EXPRESSION={$_.CSName}}, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.LastBootUpTime)}}
}

# Depending on where you store your profile.ps1, you may get a lot of SYSTEM transcripts.
# This function deletes them.
Function DeleteSystemTranscripts {
        Write-Host "Deleting any transcripts created by the SYSTEM user."
        $systemTranscripts = Get-ChildItem $transcriptPath | Select-String -Pattern "Username:[^\\]*\\SYSTEM" | Select-Object -ExpandProperty Path
        ForEach ($systemTranscript in $systemTranscripts) {
                Remove-Item $systemTranscript -ErrorAction SilentlyContinue
        }
}

# Delete transcripts older than $days.
Function DeleteOldTranscripts {
        $days = 90
        Write-Host "Deleting transcripts older than $days days."
        $oldTranscripts = Get-ChildItem $transcriptPath | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-$days)}
        ForEach ($oldTranscript in $oldTranscripts) {
                Remove-Item $oldTranscript -ErrorAction SilentlyContinue
        }
}

# So I don't have to remember how to connect to Office365 all the time.
Function Connect-Office365 {
        $session365 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential (Get-Credential) -Authentication Basic -AllowRedirection
        Import-PSSession $session365
        Write-Host ("`r`nUse 'Remove-PSSession -Id " + $session365.Id + "' to end session.") -ForegroundColor "Yellow"
}

# Run the DeleteOldTranscripts function every time profile loads.
# This can significantly impact the loading time of a shell.
# Better to accomplish this via a scheduled task.
#DeleteOldTranscripts


# Clear the screen so we don't see any mess from loading.
Clear-Host

# Settings specific to running as admin
# Post a warning about running as admin.
& {
  $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp=New-Object System.Security.Principal.WindowsPrincipal($wid)
  $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  $IsAdmin=$prp.IsInRole($adm)
  If ($IsAdmin)
  {
    Write-Host "RUNNING AS ADMIN. USE CAUTION." -ForegroundColor "Red"
  }
}

# Show uptime before prompt
uptime
