#Import-Module $env:SyncroModule

# Try/catch to make sure Get-Tpm cmdlet is available.
# If Get-Tpm is not available, exit script because Windows version is not supported by this script.
try {
    # Make sure TPM is activated. Exits with an error if there is no TPM.
    if (!((Get-Tpm).TpmActivated -eq $true)) {
        Write-Output "TPM not present or not activated. Exiting."
        Exit 1
    }
}
catch {
    Write-Output "Get-Tpm command did not work."
    Write-Output "This script only works on Windows 10, Server 2016, or newer. Exiting."
    Exit 1
}

# Only attempt to enable BitLocker if it is not already enabled for the OS volume.
if (!(Get-BitLockerVolume -MountPoint $Env:SystemDrive -ErrorAction SilentlyContinue).ProtectionStatus -eq "On") {
    Get-BitLockerVolume -MountPoint $Env:SystemDrive | Enable-BitLocker -EncryptionMethod XtsAes128 -RecoveryPasswordProtector
    Write-Output "BitLocker enabled on $Env:ComputerName. Please reboot to begin encryption."
}

# Get the recovery password and attach it to the asset.
$bitlockerRecoveryPassword = ((Get-BitLockerVolume -MountPoint $Env:SystemDrive).KeyProtector.RecoveryPassword | Out-String).Trim()
#Set-Asset-Field -Name "BitLocker Recovery Password" -Value $bitLockerRecoveryPassword
Write-Output "Recovery Password: $bitlockerRecoveryPassword"
Exit 0