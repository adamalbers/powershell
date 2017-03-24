#Start at root of system drive
Set-Location -Path $Env:SystemDrive/

#Create the transcript directory if needed
$transcriptPath = "$Env:SystemDrive/AMP/Transcripts"
 
if (!(Test-Path $transcriptPath))
{
        New-Item $transcriptPath -Type Directory
}

#Start a transcript to record all activity in this PowerShell session
Start-Transcript -Path $Env:SystemDrive/AMP/Transcripts/powershell-$(Get-Date -Format yyyy-MM-dd-HH.mm.ss).txt -Append

#Clear screen so you don't see all the profile spam
Clear-Host​​​​​​​