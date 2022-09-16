# ----- SET PATHS HERE ----- #
$functionsPath = "/path/to/powershell/functions"
$configPath = "/path/to/powershell/configs"


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
Clear-Host
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion.ToString())"
Write-Host '------------------------------'
Write-Host -ForegroundColor Green "Using $PROFILE"
Write-Host '------------------------------'
Write-Host -ForegroundColor Green "Functions path: $functionsPath"
Write-Host -ForegroundColor Green "Configs path: $configsPath"
Write-Host '------------------------------'
Write-Host 'Importing $coreFunctions from profile:'

# Source checkUnique and importFunction (requires checkUnique).
. "$($functionsPath)/checkUnique.ps1"
. "$($functionsPath)/importFunction.ps1"

# Define any other core functions we want.
$coreFunctions = @('importAllFunctions.ps1',
                    'importConfig.ps1'
                )

# Loop through $coreFunctions and source them with importFunction
$coreFunctions | ForEach-Object {
    Write-Host -ForegroundColor Green "Importing $_" 
    importFunction $_
}