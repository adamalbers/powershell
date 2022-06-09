# This script will register Chocolatey packages in Programs and Features.
# This exposes the packages to inventory by RMMs etc.

$companyUrl = "http://www.example.com"
$companyName = "Example Inc."

# Set Chocolatey path
$chocoPath = "$Env:SystemDrive\ProgramData\Chocolatey\Bin\Choco.exe"

# Path to file that will hold list of installed Chocolatey packages
$chocoListPath = "$Env:Temp\chocoList.txt"

# Set program icon for Programs and Features list
# Will use the Chocolatey icon so it's easy to see which items were installed via Chocolatey
$icon = $chocoPath

Function createPackage ($package) {
    
    $packageName = $package.Split()[0]
    $packageVersion = $package.Split()[1]
    
    $registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Chocolatey - $packageName"

    if (!(Test-Path $registryPath)) {
        # Create the registry key
        New-Item $registryPath -Force | Out-Null
    }
    
    Write-Host "Adding $package to Programs and Features"   

    # Create key properties
    New-ItemProperty -Path $registryPath -Name "DisplayName" -PropertyType String -Value "$packageName" | Out-Null
    New-ItemProperty -Path $registryPath -Name "DisplayVersion" -PropertyType String -Value "$packageVersion" | Out-Null
    New-ItemProperty -Path $registryPath -Name "Publisher" -PropertyType String -Value "Deployed by $companyName" | Out-Null
    New-ItemProperty -Path $registryPath -Name "UrlInfoAbout" -PropertyType String -Value "$companyUrl" | Out-Null
    New-ItemProperty -Path $registryPath -Name "Comments" -PropertyType String -Value "Chocolatey package installed by $companyName" | Out-Null
    New-ItemProperty -Path $registryPath -Name "DisplayIcon" -PropertyType String -Value "$icon" | Out-Null
    New-ItemProperty -Path $registryPath -Name "UninstallString" -PropertyType String -Value "$chocoPath uninstall $packageName -force -yes" | Out-Null
    New-ItemProperty -Path $registryPath -Name "QuietUninstallString" -PropertyType String -Value "$chocoPath uninstall $packageName -force -yes" | Out-Null
    New-ItemProperty -Path $registryPath -Name "NoModify" -PropertyType DWORD -Value "1" | Out-Null
    New-ItemProperty -Path $registryPath -Name "NoRepair" -PropertyType DWORD -Value "1" | Out-Null
}

# TODO: Delete entries for packages no longer installed

# Create list of currently installed packages
Start-Process $chocoPath -ArgumentList "list -localonly" -NoNewWindow -RedirectStandardOutput "$chocoListPath"
Start-Sleep -Seconds 2
$chocolateyPackageList = [System.Collections.ArrayList](Get-Content "$chocoListPath")

# Remove the lines of the list that are not actual package names
ForEach ($package in $chocolateyPackageList) {
    if (!($package -like "*chocolatey*" -or $package -like "*packages installed*" -or $package -like "*automatically sync*" -or $package -like "*package synchronizer*")) {
        createPackage("$package")
    }
}

Exit 0