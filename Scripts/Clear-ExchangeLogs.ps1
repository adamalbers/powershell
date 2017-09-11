# Removes log files from Exchange folders older than X days.
# This only removes diagnostic logs and has nothing to do with transaction logs.

$days=7
$IISLogPath="$Env:SystemDrive\inetpub\logs\LogFiles\"
$ExchangeLoggingPath="$Env:SystemDrive\Program Files\Microsoft\Exchange Server\V15\Logging\"
$ETLLoggingPath="$Env:SystemDrive\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces\"
$ETLLoggingPath2="$Env:SystemDrive\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs"
Function CleanLogfiles($TargetFolder)
{
    if (Test-Path $TargetFolder) {
        $LastWrite = (Get-Date).AddDays(-$days)
        $Files = Get-ChildItem $TargetFolder -Include *.log,*.blg, *.etl, *.txt -Recurse | Where-Object {$_.LastWriteTime -le "$LastWrite"}
        foreach ($File in $Files)
            {Write-Host "Deleting file $File" -ForegroundColor "white"; Remove-Item $File -ErrorAction SilentlyContinue | out-null}
       }
Else {
    Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "white"
    }
}
CleanLogfiles($IISLogPath)
CleanLogfiles($ExchangeLoggingPath)
CleanLogfiles($ETLLoggingPath)
CleanLogfiles($ETLLoggingPath2)