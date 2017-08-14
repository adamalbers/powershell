<#
.SYNOPSIS
    Download backup of PassPortal passwords
.DESCRIPTION
     Use the PassPortal/Ocular utility to download password protected ZIP file containing CSV of all password data.
     https://passportal.atlassian.net/wiki/display/PKB/Passportal+Backup+Utility
.NOTES
    Author: Adam Albers
#>

# Declare variables
$utilityPath = "$Env:SystemDrive/Program Files/Passportal/Backup Utility/PassportalBackupUtility.exe"
$passwordPath = "$Env:SystemDrive/AMP/Passwords/ocularPassword.txt"
$passphrasePath = "$Env:SystemDrive/AMP/Passwords/ocularPassphrase.txt"
$zipPasswordPath = "$Env:SystemDrive/AMP/Passwords/zipPassword.txt"
$emailAddress = "adam@ampsysllc.com"
$country = "United States"
$backupFilePath = "$Env:SystemDrive/Shares/Administration/ocularBackup.csv"
$password = Get-Content $passwordPath | ConvertTo-SecureString
$passphrase = Get-Content $passphrasePath | ConvertTo-SecureString
$zipPassword = Get-Content $zipPasswordPath | ConvertTo-SecureString

Start-Process -FilePath $utilityPath -ArgumentList EMAIL="$emailAddress" PASSWORD="$password" PASSPHRASE="$passphrase" COUNTRY="$country" EXTRACTFILEPATH="backupFilePath" ZIPFILEPASSWORD="$zipPassword"