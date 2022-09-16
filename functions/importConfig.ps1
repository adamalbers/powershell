# Imports a config JSON into your script.
# Supported extensions are .json, .secret, and .secure.
# importConfig will try to decrypt any .secret and .secure files with Keybase.
# In your script, use 'importConfig [name]'
# E.g. 'importConfig emailAccount' will search for a config with 'emailAccount' in the file name.


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
function importConfig {
    # This function imports a .json or .secret (Keybase encrypted JSON) config file and converts it to an object.
    # Requires Keybase to be installed and in your PATH for .secret files.

    Param(
        [Parameter(Mandatory = $true)] [string[]] $configName
    )
    
    # Make sure $functionsPath is defined
    if (-not $configsPath) {
        Write-Host -Red '$configsPath is not defined. Cannot proceed. Check your PowerShell profile.'
        return
    }
   
    $configFile = Get-ChildItem -Path $configsPath -Filter "*$($configName)*" -ErrorAction 'SilentlyContinue' | Where-Object {$_.Name -notmatch 'example'}

    if (-not $configFile) {
        Write-Warning "Could not find any file matching `'$configName`' in $configsPath."
        return
    }

    Write-Host -ForegroundColor Green '#----- CONFIG IMPORT -----#'
    
    $unique = checkUnique $configFile

    if (-not $unique) {
        Write-Warning "Found more than one file matching $($configName):"
        $configFile | ForEach-Object { Write-Host $_.FullName }
        Write-Warning "Please narrow your search and try again."
        return
    }

    if ($unique) {
        if (($($configFile.Name) -match '.secret') -or ($($configFile.Name) -match '.secure')) {
            if (-not (Get-Command keybase)) {
                Write-Warning "keybase does not seem to be in your PATH. Cannot decrypt config file."
                return
            }
            
            try {
                Write-Host "Attempting to import encrypted file: $($configFile.Name)."
                $configInfo = (& keybase decrypt -i $($configFile.FullName)) | ConvertFrom-Json -Depth 100
                Write-Host -ForegroundColor Green "Success"
                return $configInfo
            } 
            catch {
                Write-Warning $_
                return
            }        
            
            return
        }

        if ($($configFile.Name) -match '.json') {
            try {
                Write-Host "Attempting to import unencrypted file: $($configFile.Name)."
                $configInfo = Get-Content $($configFile.FullName) | ConvertFrom-Json -Depth 100
                Write-Host -ForegroundColor Green "Success"
            return $configInfo
            }
            catch {
                Write-Warning $_
                return 1
            }
        }
    }
    
    return "Could not import $configFile. Please verify it is a .json or .secret file."
}