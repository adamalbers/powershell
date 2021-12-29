<#
Author: Adam Albers 
    
Big thank you to Chris Taylor @ https://github.com/christaylorcodes for their Connect-CWC.ps1 that got me started.
    
connectToControl function modified from:
https://github.com/christaylorcodes/ConnectWiseControlAPI/blob/master/ConnectWiseControlAPI/Public/Authentication/Connect-CWC.ps1

$controlGUID, $companyName, and $operatingSystem are set by my RMM at runtime.
You can set them manually for testing or use outside the RMM.

Only $companyName is REQUIRED.

The script will figure out $controlGUID and $operatingSystem if needed.
#>
#$controlGUID = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
#$companyName = 'ACME CORP'
#$operatingSystem = 'Microsoft Windows 10 Professional'


# HTTPS IS REQUIRED
$server = 'http://example.domain.com'

# Instance ID is the string inside the () of the Windows service.
# E.g. ScreenConnect Client (111aaa222bbb333ccc)
$instanceID = '111aaa222bbb333ccc'

<# 
In Connectwise Control Admin:
1. Create a role called Edit Session Only.
2. Give the Edit Session Only role the EditSession permission under AllSessionGroups.
3. Create a separate user account in Control that does not require MFA.
4. Give the user a very long password (40+ chars).
5. Assign your non-MFA automation user to the Edit Session Only role.
#>
$username = 'exampleUser'
$password = 'SuperSecretAndVeryLongPassword'

#### DO NOT CHANGE ANYTHING BELOW HERE ####

# Get $controlGUID from registry if it wasn't already provided.
if ($controlGUID -eq $null) {
    [regex]$regex = '&s=.+(?=&k)'
    $controlGUID = $regex.Matches((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\ScreenConnect Client ($instanceID)").ImagePath)[0].Value
    $controlGUID = $controlGUID.Replace("&s=","")
    if ($controlGUID -eq $null) {
        Write-Output '$controlGUID is null. Cannot proceed. Please verify Control agent is installed.'
        Exit 1
    }
}

# Get $operatingSystem from CIM if it wasn't already provided.
if ($operatingSystem -eq $null) {
    $operatingSystem = (Get-CimInstance -ClassName Cim_OperatingSystem).Caption
}

# Determine if server or workstation based on OS name and change device type accordingly
if ($operatingSystem -match "Server") {
	$deviceType = "Server"
} else {
	$deviceType = "Workstation"
}

# Make sure $server has HTTPS
if ($server -notmatch 'https://') {
    Write-Output "`nProvided URL: $server"
    Write-Output "HTTPS is required. Exiting.`n"
    Exit 1
}

# Hide progress to make Invoke-WebRequest a bit faster
$ProgressPreference = 'SilentlyContinue'

function connectToControl {
    $credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($username):$($password)"))
    $headers = @{
        'authorization' = "Basic $credentials"
        'content-type' = "application/json; charset=utf-8"
        'origin' = "$server"
    }

    $results = Invoke-WebRequest -Uri $headers.origin -Headers $headers -UseBasicParsing
    $regex = [Regex]'(?<=antiForgeryToken":")(.*)(?=","isUserAdministrator)'
    $match = $regex.Match($results.content)
    if($match.Success){ $headers.'x-anti-forgery-token' = $match.Value.ToString() }
    else{ Write-Verbose 'Unable to find anti forgery token. Some commands may not work.' }

    $script:serverConnection = @{
        Server = $server
        Headers = $headers
    }
}

function updateCustomProperties {
    $body = "[[`"All Machines`"],[`"$controlGUID`"],[`"`"],[[`"$companyName`",`"`",`"`",`"$deviceType`",`"`",`"`",`"`",`"`"]]]"
    $url = "$server/Services/PageService.ashx/UpdateSessions"

    Invoke-RestMethod -Headers $($serverConnection.Headers) -Method POST -Body $body -Uri $url
}

connectToControl
updateCustomProperties

Remove-Variable -Name serverConnection

Exit 0