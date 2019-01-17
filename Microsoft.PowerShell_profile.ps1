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
Start-Transcript -Path $transcriptPath/powershell-$(Get-Date -Format yyyy-MM-dd-HH.mm.ss).txt -Append

#Functions

Function uptime {
        Get-WmiObject Win32_OperatingSystem | Select-Object @{LABEL='Computer';EXPRESSION={$_.CSName}}, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.LastBootUpTime)}}
}

Function Connect-Office365 {
        $session365 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential (Get-Credential) -Authentication Basic -AllowRedirection
        Import-PSSession $session365
        Write-Host ("`r`nUse 'Remove-PSSession -Id " + $session365.Id + "' to end session.") -ForegroundColor "Yellow"       
}

Clear-Host

#Settings specific to running as admin
=======
#Post a warning about running as admin and delete transcripts created by SYSTEM user
>>>>>>> f9e503585207967bbd8d27de4f1a54cf8df5d067
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
