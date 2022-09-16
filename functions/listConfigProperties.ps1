# List out the names of properties found in the given config file.

function listConfigProperties {
    Param (
        [Parameter(Mandatory)] $thisConfig
    )
    
    Write-Host "$thisConfig"
    $properties = ($thisConfig | Get-Member | Where-Object {$_.MemberType -eq 'NoteProperty'}).Name
    Write-Host '------------------------------'
    Write-Host "Found the following properties in $($thisConfig):"
    $properties | ForEach-Object {
        Write-Host "$_"
    }
    Write-Host '------------------------------'
    return
}