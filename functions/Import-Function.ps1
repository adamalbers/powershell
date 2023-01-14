# Sources a function file from your $functionsPath (set in PowerShell profile) into your script.
# In your script, just use 'Import-Function [name]'
# E.g. 'Import-Function Get-ScriptName' will search for a file called 'Get-ScriptName' in the $functionsPath directory.
# You can include the file extension if you wish, but it is not necessary.
# Make sure your file names match the function names inside the file!!


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
function Import-Function {
    Param(
        [Parameter(Mandatory = $true)] [string[]] $functionName
    )

    # Make sure $functionsPath is defined
    if (-not $functionsPath) {
        Write-Host -Red '$functionsPath is not defined. Cannot proceed. Check your PowerShell profile.'
        return
    }

    # Try to import Test-Unique if it's not already available.
    if (-not (Get-Command Test-Unique -ErrorAction 'SilentlyContinue')) {
        try { 
            . "$($functionsPath)/Test-Unique.ps1"
        }
        catch {
            Write-Error 'Seem to missing the Test-Unique function. Cannot proceed.'
            return
        }
    }

    # Try to find the *.ps1 file called $functionName
    $functionFile = Get-ChildItem -Path $functionsPath -Filter "*$($functionName)*.ps1" -ErrorAction 'SilentlyContinue'

    # Warn and return if $functionName not found
    if (-not $functionFile) {
        Write-Warning "Could not find any file matching `'$functionName`' in $functionsPath."
        return
    }
    
    # Check if only one file matched the search
    $unique = Test-Unique $functionFile

    # Warn and return if multiple files matched the search
    if (-not $unique) {
        Write-Warning "Found more than one file matching `'$($functionName)`':"
        $functionFile | ForEach-Object { Write-Host $_ }
        Write-Warning "Please narrow your search and try again."
        return
    }
    
    # If only one file matched, try to source the .ps1 file.
    if ($unique) {
        Write-Host "Found $($functionFile.Name) in $functionsPath." 
    
        try { 
            Write-Host "Attempting to import $($functionFile.Name)."
            
            # Use a wrapper to make sure the function is available in the global scope.
            # See: https://stackoverflow.com/questions/15187510/dot-sourcing-functions-from-file-to-global-scope-inside-of-function
            $script = Get-Content -Path $($functionFile.FullName)
            $script = $script -replace '^function\s+((?!global[:]|local[:]|script[:]|private[:])[\w-]+)', 'function Global:$1'
            $function = ([ScriptBlock]::Create($script))

            $function -split [Environment]::NewLine
            
            # Dot source the function. This is the actual import step.
            return $function
            
            Write-Host -ForegroundColor Green "Succes"
        }
        catch {
            Write-Warning $_
            return
        }
    }
    return    
}

