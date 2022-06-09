<#
.SYNOPSIS
    Script verifies PDC time is the time source for domain machines. Outputs results
    to a txt file.
.NOTES
    File Name  : Check-TimeSync.ps1
    Author     : Adam Albers
.LINK
    https://github.com/adamalbers/powershell
#>

Import-Module ActiveDirectory

# Get domain info so we can check the PDC Emulator, which is the master time server for the domain.
$domain = Get-ADDomain
$pdcEmulator = $domain.PDCEmulator

$pdcSource = w32tm /query /computer:$pdcEmulator /source

$computerList = Get-ADComputer -Filter { Enabled -eq $true } | Where-Object { $_.DNSHostName -ne $pdcEmulator } | Sort-Object Name
$mismatchListFile = "$Env:SystemDrive\AMP\Reports\timeSyncMismatch-$(Get-Date -Format yyyy-MM-dd).txt"

ForEach ($computer in $computerList) {
    $timeSource = w32tm /query /computer:$($computer.DNSHostName) /source
    If ($timeSource -ne $pdcEmulator) {
        $computer.Name | Out-File $mismatchListFile -Append
    }
}