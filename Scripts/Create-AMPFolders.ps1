# Create standard AMP directories for holding logs, scripts, etc.
# The passwordsPath should only be used to store secure string passwords. If you have plaintext passwords in here, you're doing it wrong.
 
 $rootPath = "$Env:SystemDrive/AMP"
 $logPath = "$Env:SystemDrive/AMP/Logs"
 $passwordPath = "$Env:SystemDrive/AMP/Passwords"
 $scriptPath = "$Env:SystemDrive/AMP/Scripts"
 $reportPath = "$Env:SystemDrive/AMP/Reports"
  
  $pathArray = $rootPath,$logPath,$passwordPath,$scriptPath,$reportPath
   
   ForEach ($directory in $pathArray)
   {
       if (!(Test-Path $directory))
       {
           New-Item $directory -Type Directory
       }
   }

