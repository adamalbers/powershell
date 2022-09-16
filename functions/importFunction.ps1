# Sources a function file from your $functionsPath (set in PowerShell profile) into your script.
# In your script, just use 'importFunction [name]'
# E.g. 'importFunction getUptime' will search for a function with 'getUptime' in the file name.


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
function importFunction {
    Param(
        [Parameter(Mandatory = $true)] [string[]] $functionName
    )

    # Make sure $functionsPath is defined
    if (-not $functionsPath) {
        Write-Host -Red '$functionsPath is not defined. Cannot proceed. Check your PowerShell profile.'
        return
    }

    # Try to find the *.ps1 file called $functionName
    $functionFile = Get-ChildItem -Path $functionsPath -Filter "*$($functionName)*.ps1" -ErrorAction 'SilentlyContinue'

    # Warn and return if $functionName not found
    if (-not $functionFile) {
        Write-Warning "Could not find any file matching `'$functionName`' in $functionsPath."
        return
    }
    
    # Check if only one file matched the search
    $unique = checkUnique $functionFile

    # Warn and return if multiple files matched the search
    if (-not $unique) {
        Write-Warning "Found more than one file matching $($functionName):"
        $functionFile | ForEach-Object { Write-Host $_ }
        Write-Warning "Please narrow your search and try again."
        return
    }
    
    # If only one file matched, try to source the .ps1 file.
    if ($unique) {
          Write-Host "Found $($functionFile.Name) in $functionsPath." 
    
        try { 
            Write-Host "Attempting to import $($functionFile.Name)."
            . $functionFile
            Write-Host -ForegroundColor Green "Succes"
        }
        catch {
            Write-Warning $_
            return
         }
    }
    return    
}

