Import-Module AzureAD
Import-Module ExchangeOnlineManagement

# Connect to Azure AD to get list of tenants
$azureADSession = Connect-AzureAD
$customers = (Get-AzureADContract)

# Get the UPN of the logged in Azure AD admin for future commands
$userPrincipalName = $azureADSession.Account.Id

function connectExchangeOnline {
    param (
        $thisCustomer
    )
    Write-Output "Connecting to $($thisCustomer.DisplayName)`n"
    Connect-ExchangeOnline -UserPrincipalName $userPrincipalName -DelegatedOrganization "$($thisCustomer.CustomerContextId)" -ShowBanner:$false -ErrorAction 'SilentlyContinue'

}
function enableAdminAuditLog {
    param (
        $thisCustomer
    )
    
    if ((Get-OrganizationConfig).IsDehydrated -eq $true) {
        Enable-OrganizationCustomization -Confirm:$false
    }
    Write-Output "Enabling Admin Audit Log for $($thisCustomer.DisplayName)."
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
}

function disconnectExchangeOnline {
    param (
        $thisCustomer
    )
    
    Write-Output "Disconnecting from $($thisCustomer.DisplayName)"
    Disconnect-ExchangeOnline -Confirm:$false
}


foreach ($customer in $customers) {
    connectExchangeOnline $customer
    enableAdminAuitLog $customer
    disconnectExchangeOnline $customer
    
    Write-Output "Sleeping 5 seconds before moving on to next tenant. `n`n"
    Start-Sleep -Seconds 5
}

