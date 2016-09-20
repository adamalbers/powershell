# From http://stackoverflow.com/questions/17829785/delete-files-older-than-15-days-using-powershell

$limit = (Get-Date).AddDays(-15)
$path = "C:\Some\Path"

# Delete files older than the $limit.
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
