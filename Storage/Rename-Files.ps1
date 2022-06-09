# Renames files in bulk by replacing characters.
# E.g. Used for changing "oldText" to "newText" in file name, while leaving the rest of the file name unchanged.

$directoryPath = Read-Host "Path (. for current directory): "
$oldText = Read-Host "OLD text to be replaced: "
$newText = Read-Host "NEW text: "

$fileList = Get-ChildItem -Path $directoryPath

# Change to $directoryPath to work on files
Set-Location $directoryPath

# Rename files
foreach ($file in $fileList) {
    Rename-Item $file.Name $($file.Name).Replace($oldText, $newText)
}