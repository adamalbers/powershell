<#
.SYNOPSIS
   Deletes old Exchange diagnostic logs.
.DESCRIPTION
    This script does not touch transaction logs. It only deletes diagnostic logs
    that tend to fill up drive space.
.NOTES
    File Name  : Clear-ExchangeLogs.ps1
    Author     : Adam Albers
.LINK
    https://github.com/adamalbers/powershell
#>

# Files older than $days will be deleted.
$days = 7

$IISLogPath = "$Env:SystemDrive\inetpub\logs\LogFiles\"
$ExchangeLoggingPath = "$Env:SystemDrive\Program Files\Microsoft\Exchange Server\V15\Logging\"
$ETLLoggingPath = "$Env:SystemDrive\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces\"
$ETLLoggingPath2 = "$Env:SystemDrive\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs"
Function CleanLogfiles($TargetFolder) {
    if (Test-Path $TargetFolder) {
        $LastWrite = (Get-Date).AddDays(-$days)
        $Files = Get-ChildItem $TargetFolder -Include *.log, *.blg, *.etl, *.txt -Recurse | Where-Object { $_.LastWriteTime -le "$LastWrite" }
        foreach ($File in $Files)
        { Write-Host "Deleting file $File" -ForegroundColor 'white'; Remove-Item $File -ErrorAction SilentlyContinue | Out-Null }
    }
    Else {
        Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor 'white'
    }
}
CleanLogfiles($IISLogPath)
CleanLogfiles($ExchangeLoggingPath)
CleanLogfiles($ETLLoggingPath)
CleanLogfiles($ETLLoggingPath2)

Exit 0