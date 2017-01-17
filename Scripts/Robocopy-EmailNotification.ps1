# Requires PowerShell 3.0 or higher.
# This is intended to be used for on-demand robocopy jobs. It will not save the email password so this won't work as a scheduled task.

  $SourceFolder = "c:\example\path\source"
  $DestinationFolder = "\\example\path\destination"
  $FileList = "*.txt"
  $Logfile = "$Env:SystemDrive/AMP/Logs/Robocopy-" + (Get-Date -uFormat "%m%d%Y%H%M%S").tostring() + ".log"

    $EmailFrom = "ampsys@ampsyscloud.com"
# Prompt for email password when running script
    $credentials = Get-Credential -UserName $EmailFrom -Message "Email Password"

# Mutliple recipients in the form @("first@person.com","second@person.com")
      $EmailTo = @("adam@ampsysllc.com")

        $EmailBody = "Robocopy - See attached log file for details"
        $EmailSubject = "Robocopy Done on $env:COMPUTERNAME"
        $SMTPServer = "smtp.sendgrid.net"
        $SMTPPort = "587"

# Load Robocopy Arguments
# See https://technet.microsoft.com/en-us/library/cc733145.aspx for options
# If you use /COPYALL you must Run As Administrator
          $Options = @("/R:0","/W:0","/Z","/LOG+:$Logfile","/TEE","/S","/E")
          $RobocopyArgs = @($SourceFolder,$DestinationFolder,$FileList,$Options)

# Run robocopy
            robocopy @RobocopyArgs

# Send email with log attached
              Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Attachments $Logfile -Body $EmailBody -SmtpServer $SMTPServer -Port $SMTPPort -Credential $credentials -UseSSL
