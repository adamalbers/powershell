$registryObjects = @()

$osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption

Write-Output "Detected $osVersion."

if ($osVersion -notmatch "10" -and $osVersion -notmatch "11") {
    Write-Output "This script only works on Windows 10 Pro or Windows 11 Pro. Exiting."
    Exit 1
}

if ($osVersion -match "11") {
    Write-Output "Windows 11 detected. Attempting to set rollback period to 60 days."
    & dism.exe /Online /Set-OSUninstallWindow /Value:60
    Start-Sleep -Seconds 5
    & dism.exe /online /Get-OSUninstallWindow
    Exit 1
}

$registryObjects += [PSCustomObject]@{
    KeyPath = 'HKLM:/SOFTWARE/Policies/Microsoft/Windows/WindowsUpdate'
    Name = 'ProductVersion'
    Type = 'String'
    Value = 'Windows 10'
}

$registryObjects += [PSCustomObject]@{
    KeyPath = 'HKLM:/SOFTWARE/Policies/Microsoft/Windows/WindowsUpdate'
    Name = 'TargetReleaseVersion'
    Type = 'DWord'
    Value = '1'
}

$registryObjects += [PSCustomObject]@{
    KeyPath = 'HKLM:/SOFTWARE/Policies/Microsoft/Windows/WindowsUpdate'
    Name = 'TargetReleaseVersionInfo'
    Type = 'String'
    Value = '21H1'
}

foreach ($registryObject in $registryObjects) {
    if (-not (Test-Path -Path $($registryObject.KeyPath) -ErrorAction 'SilentlyContinue')) {
        Write-Output "$($registryObject.KeyPath) not found. Creating registry key."
        New-Item -Path $($registryObject.KeyPath)
    }
    
    Write-Output "Setting $($registryObject.KeyPath) property $($registryObject.Name) to value: $($registryObject.Value)"
    New-ItemProperty -Path $($registryObject.KeyPath) -Name $($registryObject.Name) -Value $($registryObject.Value) -PropertyType $($registryObject.Type) -ErrorAction 'SilentlyContinue'
    Set-ItemProperty -Path $($registryObject.KeyPath) -Name $($registryObject.Name) -Value $($registryObject.Value)
    
    Write-Output "`n`nDone setting $($registryObject.Name)."
    Get-ItemProperty -Path $($registryObject.KeyPath) -Name $($registryObject.Name)
}



Exit 0