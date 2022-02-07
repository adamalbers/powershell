$csvFolder = "C:\Example"

Connect-MsolService
$myTenantID = ((Get-MsolAccountSku)[0].AccountObjectID).toString()
$tenants = Get-MsolPartnerContract

$allUsers = @()

function getUsers {
    param (
        [Parameter(Mandatory = $true)]
        $thisTenant
    )
    $users = @()
    
    try {
        $userList = Get-MsolUser -TenantID $thisTenant.TenantID -ErrorAction Stop
    }
    catch {
        Write-Host "Unable to connect to $($thisTenant.DefaultDomain). Please check delegated permisisons."
        return
    }
    
    foreach ($user in $userList) {
        $mfaMethods = $($user.StrongAuthenticationMethods.MethodType)
        $mfaDefaultMethod = $($user.StrongAuthenticationMethods | Where-Object {$_.IsDefault -eq $true}).MethodType
        
        if ($($user.StrongAuthenticationMethods) -ne $null) {
            $mfaEnabled = "True"
            
        } else {
            $mfaEnabled = "False"
        }
        
        $userObject = [PSCustomObject]@{
            TenantDefaultDomain     = "$($thisTenant.DefaultDomainName)"
            TenantID                = "$($thisTenant.TenantID)"
            UserPrincipalName       = "$($user.UserPrincipalName)"
            MFAEnabled              = "$($mfaEnabled)"
            DefaultMFAMethod        = "$($mfaDefaultMethod)"
            MFAMethods              = "$($mfaMethods -Join ' | ')"
            PasswordNeverExpires    = "$($user.PasswordNeverExpires)"
            WhenCreated             = "$($user.WhenCreated)"
            PasswordLastChanged     = "$($user.LastPasswordChangeTimestamp)"
        }

        $users += $userObject
    }

    
    return $users
}

$allUsers += getUsers $myTenantID

foreach ($tenant in $tenants) {
    $allUsers += getUsers $tenant
}

# Export results to CSV
$allUsers | Export-Csv "$csvFolder\allUsers.csv" -NoTypeInformation

# Disconnect from MSOL
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()

Exit 0