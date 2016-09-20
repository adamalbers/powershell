# Create standard AMP directories for holding logs, scripts, etc.
# The passwordsPath should only be used to store secure string passwords. If you have plaintext passwords in here, you're doing it wrong.
 
 $rootPath = "C:\AMP"
 $logPath = "C:\AMP\Logs"
 $passwordPath = "C:\AMP\Passwords"
 $scriptPath = "C:\AMP\Scripts"
 $reportPath = "C:\AMP\Reports"
  
  $pathArray = $rootPath,$logPath,$passwordPath,$scriptPath,$reportPath
   
   ForEach ($directory in $pathArray)
   {
       if (!(Test-Path $directory))
       {
           New-Item $directory -Type Directory
       }
   }

