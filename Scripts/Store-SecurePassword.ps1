# Use this to save a secure password for running future jobs
 
# Prompt for password file name
$fileName = Read-Host "Enter file name (e.g. emailPassword.txt): "
  
# Prompt the user to enter a password
$secureString = Read-Host "Enter password: " | ConvertTo-SecureString -AsPlainText -Force

# Save encrypted password to file
$secureString | ConvertFrom-SecureString | Out-File "$Env:SystemDrive/AMP/Passwords/$fileName"
