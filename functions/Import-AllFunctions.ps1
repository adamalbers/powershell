# Imports every function in your $functionsPath (set in your PowerShell profile).
# Probably not a good idea to ever run this since it will load a bunch of crap you don't need.


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
Import-Function Get-ScriptName

function Import-AllFunctions {
    $thisScript = Get-ScriptName
    
    try {
        Write-Host "Attempting to import all functions from $functionsPath."
        $functions = Get-ChildItem -Path $functionsPath -Filter *.ps1 | Where-Object {$_.FullName -notmatch $thisScript} | ForEach-Object {
            Write-Host "Importing $($_.Name)"

            # Use a wrapper to make sure the function is available in the global scope.
            # See: https://stackoverflow.com/questions/15187510/dot-sourcing-functions-from-file-to-global-scope-inside-of-function
            $script = Get-Content -Path $($_.FullName)
            $script = $script -replace '^function\s+((?!global[:]|local[:]|script[:]|private[:])[\w-]+)', 'function Global:$1'
            $function = ([ScriptBlock]::Create($script))
            
            # Dot source the function. This is the actual import step.
            . $function
        }
    }
    catch {
        Write-Warning $_
        return
    }

    Write-Host -ForegroundColor Green "Success"
    return
}