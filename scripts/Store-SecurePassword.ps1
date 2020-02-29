# Use this to save a secure password for running future jobs
 
# Prompt for password file name
$fileName = Read-Host "Enter file name (e.g. emailPassword.txt): "
  
# Prompt the user to enter a password
$password = Read-Host "Enter password: " -AsSecureString
$secureStringPassword =  $password | ConvertTo-SecureString -AsPlainText -Force

# Save encrypted password to file
$secureStringText = $secureStringPassword | ConvertFrom-SecureString 
Set-Content "$Env:SystemDrive/AMP/Passwords/$fileName" $secureStringText
