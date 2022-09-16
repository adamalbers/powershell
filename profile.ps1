# ----- SET PATHS HERE ----- #
$functionsPath = "/path/to/powershell/functions"
$configPath = "/path/to/powershell/configs"


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
Clear-Host
Write-Host '#----- Loading Profile -----#'
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion.ToString())"
Write-Host '------------------------------'
Write-Host -ForegroundColor Green "Using $PROFILE"
Write-Host '------------------------------'
Write-Host -ForegroundColor Green "Functions path: $functionsPath"
Write-Host -ForegroundColor Green "Configs path: $configsPath"
Write-Host '------------------------------'
Write-Host 'Importing $coreFunctions from profile:'

# Define any other core functions we want.
# Both importFunction and importConfig require checkUnique.
$coreFunctions = @('checkUnique.ps1',
                    'importFunction.ps1',
                    'importConfig.ps1'
                )

# Loop through $coreFunctions and source them with importFunction
$coreFunctions | ForEach-Object {
    Write-Host -ForegroundColor Green "Importing $_" 
    . "$($functionsPath)/$($_)"
}

Write-Host '------------------------------'
Write-Host '#----- Profile Loaded -----#'