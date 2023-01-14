# ----- SET PATHS HERE ----- #
$functionsPath = '/path/to/powershell/functions'
$configPath = '/path/to/powershell/configs'


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
Clear-Host # Clear the default output before we write our own.
Write-Host '#----- Loading Profile -----#'
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion.ToString())"
Write-Host '------------------------------'
Write-Host -ForegroundColor Green "Using $PROFILE"
Write-Host '------------------------------'
Write-Host -ForegroundColor Green "Functions path: $functionsPath"
Write-Host -ForegroundColor Green "Configs path: $configsPath"
Write-Host '------------------------------'
Write-Host 'Importing functions:'

# ----- IMPORT ALL FUNCTIONS ----- #
$functions = (Get-ChildItem -Path $functionsPath -Filter '*.ps1' -Recurse).FullName

# Loop through $functions and source them
$functions | ForEach-Object {
    Write-Host -ForegroundColor Green "Importing $_" 
    . "$_"
}


Write-Host '------------------------------'
Write-Host '#----- Profile Loaded -----#'