Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

#### DO NOT MODIFY BELOW THIS LINE ###
$logPath = Read-Host 'Enter path to save log file e.g. C:\Temp'
$sender = Read-Host 'Enter SENDER email address'
$subject = Read-Host 'Enter all or part of message SUBJECT'
$sentDateStart = Read-Host 'Enter sent window START e.g. 01/03/2023'
$sentDateEnd = Read-Host 'Enter sent window END e.g. 01/04/2023'
$mailboxServer = Read-Host "Enter SERVER name or hit enter to use $($Env:ComputerName)"
$now = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'

if (-not $mailboxServer) {
    $mailboxServer = $($Env:ComputerName)
}

$searchQuery = "From:`"$sender`" Subject:`"*$subject*`" Sent>=$sentDateStart Sent<=$sentDateEnd"

$mailboxes = Get-Mailbox -Filter "ServerName -eq `"$mailboxServer`" -and RecipientTypeDetails -eq `"UserMailbox`"" -ResultSize Unlimited

$mailboxCount = ($mailboxes | Measure-Object).Count

Write-Host -ForegroundColor Yellow "Found $mailboxCount mailboxes on $mailboxServer..."

# Make them type DELETE to delete messages.
$delete = Read-Host 'Type DELETE in all caps to remove messages or press enter to see estimated results size'

if ($delete -ceq 'DELETE') {
    # Null the $delete variable and make them type DELETE again to confirm.
    $delete = ''
    Write-Host -ForegroundColor Red "#### You are about to DELETE messages from $mailboxCount mailboxes. Are you sure?! ####"
    Write-Host "`nDouble check your search query."
    Write-Host -ForegroundColor Yellow "$searchQuery"
    $delete = Read-Host 'Type DELETE again to proceed or hit enter to estimate results'
}

if ($delete -ceq 'DELETE') {
    Write-Host -ForegroundColor Red 'DELETE confirmed. Proceeding to delete messages. Hit CTRL-C to break.'
    $deleteLogPath = "$logPath\$now-message-DELETE-results.log"
    Write-Output $searchQuery | Out-File -FilePath $deleteLogPath
    $mailboxes | Search-Mailbox -SearchQuery { $searchQuery } -SearchDumpster -DeleteContent | Tee-Object -FilePath "$logPath\$now-message-DELETE-results.log" -Append
}

if ($delete -cne 'DELETE') {
    Write-Host -ForegroundColor Green 'Estimating results only.'
    $estimateLogPath = "$logPath\$now-message-estimate-results.log"
    Write-Output $searchQuery | Out-File -FilePath $estimateLogPath
    $mailboxes | Search-Mailbox -SearchQuery { $searchQuery } -SearchDumpster -EstimateResultOnly -Confirm:$false | Tee-Object -FilePath $estimateLogPath -Append
}

Exit 0