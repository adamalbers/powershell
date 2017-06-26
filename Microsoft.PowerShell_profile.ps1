#Requires -Version 2.0

<#
.SYNOPSIS
        AMP Systems PowerShell Profile
.DESCRIPTION
        Standard PowerShell profile installed on all servers managed by AMP Systems, LLC.
        Includes common functions, transcription, and transcript cleanup.
        Should be saved to $Env:WinDir/System32/WindowsPowershell/v1.0/Microsoft.Powershell_profile.ps1
.NOTES:
        Author: Adam Albers

#>

#Start at root of system drive
Set-Location -Path $Env:SystemDrive/

#Create the transcript directory if it does not exist
$transcriptPath = "$Env:SystemDrive/AMP/Transcripts"
 
if (!(Test-Path $transcriptPath))
{
        New-Item $transcriptPath -Type Directory
}

#Start a transcript to record all activity in this PowerShell session
Start-Transcript -Path $Env:SystemDrive/AMP/Transcripts/powershell-$(Get-Date -Format yyyy-MM-dd-HH.mm.ss).txt -Append

#Functions

Function uptime {
        Get-WmiObject Win32_OperatingSystem | Select-Object @{LABEL='Computer';EXPRESSION={$_.CSName}}, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.LastBootUpTime)}}
}

Function DeleteSystemTranscripts {
        Write-Host "Deleting any transcripts created by the SYSTEM user."
        $systemTranscripts = Get-ChildItem $transcriptPath | Select-String -Pattern "Username:[^\\]*\\SYSTEM" | Select-Object -ExpandProperty Path
        ForEach ($systemTranscript in $systemTranscripts) {
                Remove-Item $systemTranscript -ErrorAction SilentlyContinue
        }
}

Function DeleteOldTranscripts {
        $days = 90
        Write-Host "Deleting transcripts older than $days days."
        $oldTranscripts = Get-ChildItem $transcriptPath | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-$days)}
        ForEach ($oldTranscript in $oldTranscripts) {
                Remove-Item $oldTranscript -ErrorAction SilentlyContinue
        }
}

Function Connect-Office365 {
        $session365 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential (Get-Credential) -Authentication Basic -AllowRedirection
        Import-PSSession $session365
        Write-Host ("`r`nUse 'Remove-PSSession -Id " + $session365.Id + "' to end session.") -ForegroundColor "Yellow"       
}
#Delete old transcripts
DeleteOldTranscripts

#Settings specific to running as admin
& {
  $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp=New-Object System.Security.Principal.WindowsPrincipal($wid)
  $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  $IsAdmin=$prp.IsInRole($adm)
  If ($IsAdmin)
  {
    Write-Host "RUNNING AS ADMIN. USE CAUTION." -ForegroundColor "Red"
    DeleteSystemTranscripts
  }
}

#Show uptime before prompt
uptime