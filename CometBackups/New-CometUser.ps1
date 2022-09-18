#Import-Module $env:SyncroModule

# Enter Comet server info here
$adminUsername = "admin"
$adminPassword = "admin"
$serverURL = "https://backups.example.com:443" # You really only need the port if it's not 443
$defaultPolicyID = "fffffff-ffff-ffff-1111-fffffffff"

# This is the account you want to create for a Comet backups user.
# I have commented out these lines because we pull them from our RMM.
#$cometUsername = "backups@example.com"
#$cometPassword = "fakePassword@34"
#$cometAccountName = "Example Corp, INC."

# Exit script if either cometUsername or cometPassword are not populated in RMM (or defined above).
if (($null -eq $cometUsername) -or ($null -eq $cometPassword)) {
    Write-Output "Please populate the Comet Backups User and Comet Backups Password fields in the customer custom fields before running this script."
    Exit 1
}

# Force TLS 1.2 encryption for the web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Establish Comet API authentication
$cometAuth = @{
    Username = "$adminUsername";
    AuthType = "Password";
    Password = "$adminPassword"
}

# Get Comet user profile to see if account already exists on Comet server
function Get-CometUserProfile {
    $apiMethod = "/api/v1/admin/get-user-profile"
    $url = "${serverURL}${apiMethod}"
    $body = $cometAuth + @{
        TargetUser = "$cometUsername"	
    }
    $getResponse = Invoke-RestMethod -Uri $url -Method POST -Body $body

    return $getResponse
}

function Set-CometUserProfile {
    $cometProfile = Get-CometUserProfile
    $cometProfile.AccountName = "$cometAccountName"
    $cometProfile.PolicyID = "$defaultPolicyID"
    $cometProfile = ConvertTo-JSON $cometProfile -Depth 99   
    $apiMethod = "/api/v1/admin/set-user-profile"
    $url = "${serverURL}${apiMethod}"
    $body = $cometAuth + @{
        TargetUser  = "$cometUsername"
        ProfileData = $cometProfile
    }

    $setResponse = Invoke-RestMethod -Uri $url -Method POST -Body $body

    return $setResponse
}

function New-CometUser {
    Write-Output "`n$response"
    Write-Output "`n$cometUsername not found on Comet server."
    Write-Output "Creating $cometUsername."

    $apiMethod = "/api/v1/admin/add-user"
    $url = "${serverURL}${apiMethod}"
    $body = $cometAuth + @{
        TargetUser        = "$cometUsername"
        TargetPassword    = "$cometPassword"
        StoreRecoveryCode = "1"
    }

    $createResponse = Invoke-RestMethod -Uri $url -Method POST -Body $body

    Write-Output $createResponse

    $createResponse = Get-CometUserProfile

    Write-Output $createResponse

    return $createResponse
}

$response = Get-CometUserProfile

# Invoke-RestMethod Status will be null if it returns good data, meaning a Comet user already exists.
# If it returns anything other than $null e.g. HTTP 400 or HTTP 500 response then the user does not exist.
if ($null -eq $response.Status) {
    Write-Output "User already exists on Comet server. Exiting."
    Exit 0
}

if ($null -ne $response.Status) {
    New-CometUser
    Set-CometUserProfile
    #Log-Activity -Message "Create $cometUsername account on $serverURL" -EventName "Comet User Creation"
}

Exit 0