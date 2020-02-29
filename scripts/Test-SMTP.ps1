$sendingMailServer = "mail.example.com"
$receivingMailServer = "mail.contoso.com"
$mailFrom = "user@example.com"
$rcptTo = "user@contoso.com"
$port = 25

$logFile = $Env:Temp + "\smtpTest-" + $(Get-Date -Format "yyyy-MM-dd-HH-mm-ss") + ".log"

$WarningPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"

### DO NOT CHANGE ANYTHING BELOW THIS LINE ###

$data = @"
From: <$mailFrom>
To: <$rcptTo>
Subject: Telnet SMTP Test

This is a test message send via telnet in order to test SMTP.
"@

$commands = @("HELO $sendingMailServer","MAIL FROM: <$mailFrom>","RCPT TO: <$rcptTo>","DATA","$data",".","QUIT")

function readResponse {

   while($stream.DataAvailable)  
      {  
         $read = $stream.Read($buffer, 0, 1024)    
         Write-Output ($encoding.GetString($buffer, 0, $read)) | Tee-Object -Append -FilePath $logFile
         Start-Sleep -Seconds 1
      } 
}

$socket = New-Object System.Net.Sockets.TcpClient($receivingMailServer, $port) 
if ($socket -eq $null) { 
   Write-Output "Unable to connect to $receivingMailServer. Quitting." | Tee-Object -Append -FilePath $logFile
   Exit 1
}

$stream = $socket.GetStream() 
$writer = New-Object System.IO.StreamWriter($stream) 
$buffer = New-Object System.Byte[] 1024 
$encoding = New-Object System.Text.AsciiEncoding


foreach ($command in $commands) {
   readResponse($stream) 
   $writer.WriteLine($command) 
   $writer.Flush()
   Write-Output "$command" | Tee-Object -Append -FilePath $logFile
   Start-Sleep -Seconds 1
}

## Close the streams 
$writer.Close() 
$stream.Close()

Write-Output "Log file saved to $logFile."

Exit 0