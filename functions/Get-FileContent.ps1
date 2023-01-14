# Using [System.IO.File] is 2x faster than using Get-Content but much more tedious to use.

function Get-FileContent {

    param (
        [Parameter(Mandatory = $true)] [string[]] $filePath
    )

    if ((Test-Path $filePath -ErrorAction 'SilentlyContinue')) {
        # Have to use Get-ChildItem first because [System.IO.File] won't like a relative path.
        $file = (Get-ChildItem -Path $filePath).FullName
        $reader = [System.IO.File]::OpenText($file)
        $fileContents = $reader.ReadToEnd() | ConvertFrom-Json -Depth 100 | Sort-Object updated_at -Descending
        $reader.Close()
        return $fileContents
    }
    else {
        Write-Host "Did not find any file at $filePath."
        return
    }
}