# Quick script made for client to reset passwords in bulk

Import-Module ActiveDirectory

$csvPath = "$Env:SystemDrive/AMP/Scripts/ADPasswordReset.csv"
# Import users and passwords from CSV
Import-Csv $csvPath | ForEach-Object {
$samAccountName = $_."samAccountName"
$newPassword = $_."password"
  
# Reset user password.
Set-ADAccountPassword -Identity $samAccountName -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force)
 
# Force user to reset password at next logon.
# Remove this line if not needed for you
Set-AdUser -Identity $samAccountName -ChangePasswordAtLogon $true

# Output each user being reset
Write-Host "AD Password has been reset for: "$samAccountName
}