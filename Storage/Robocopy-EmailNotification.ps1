# Requires PowerShell 3.0 or higher.
# This is intended to be used for on-demand robocopy jobs. It will not save the email password so this won't work as a scheduled task.

$sourceFolder = "c:\example\path\source"
$destinationFolder = "\\example\path\destination"
$fileList = "*.*"
$logFile = "C:\AMP\Logs\Robocopy-" + (Get-Date -uFormat "%m%d%Y%H%M%S").tostring() + ".log"
  

# Prompt for email password when running script
$credentials = Get-Credential -UserName "Office365 Email Address" -Message "Email Password"
  
# Mutliple recipients in the form @("first@person.com","second@person.com")
$emailTo = @("alerts@ampsysllc.com")
$emailFrom = $credentials.UserName  
$emailBody = "Robocopy - See log file for details: $logFile"
$emailSubject = "Robocopy Done on $env:COMPUTERNAME"
$smtpServer = "smtp.office365.com"
$smtpPort = "587"
  
# Load Robocopy Arguments
# See https://technet.microsoft.com/en-us/library/cc733145.aspx for options
# If you use /COPYALL you must Run As Administrator
$options = @("/R:0","/W:0","/ZB","/LOG+:$Logfile","/TEE","/COPYALL","/E","/XO","/SL","/MT")
$robocopyArgs = @($SourceFolder,$DestinationFolder,$FileList,$Options)
  
# Run robocopy
robocopy @robocopyArgs
  
# Send email with log attached
Send-MailMessage -From $emailFrom -To $emailTo -Subject $emailSubject -Body $emailBody -SmtpServer $smtpServer -Port $smtpPort -Credential $credentials -UseSSL