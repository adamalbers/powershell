# Imports every function in your $functionsPath (set in your PowerShell profile).
# Probably not a good idea to ever run this since it will load a bunch of crap you don't need.


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
importFunction getScriptName

function importAllFunctions {
    $thisScript = getScriptName
    
    try {
        Write-Host "Attempting to import all functions from $functionsPath."
        $functions = Get-ChildItem -Path $functionsPath -Filter *.ps1 | Where-Object {$_.FullName -notmatch $thisScript} | ForEach-Object {
            Write-Host "Importing $($_.Name)"
            . $_.FullName
        }
    }
    catch {
        Write-Warning $_
        return
    }

    Write-Host -ForegroundColor Green "Success"
    return
}