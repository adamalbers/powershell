# This script uses interactive authentication to 365.
# This script will enable the admin audit policy for each tenant.

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
    Write-Host "Connecting to $($thisCustomer.DisplayName)`n"
    Connect-ExchangeOnline -UserPrincipalName $userPrincipalName -DelegatedOrganization "$($thisCustomer.CustomerContextId)" -ShowBanner:$false -ErrorAction 'SilentlyContinue'

}
function enableAdminAuditLog {
    param (
        $thisCustomer
    )
    
    if ((Get-OrganizationConfig).IsDehydrated -eq $true) {
        Enable-OrganizationCustomization -Confirm:$false
    }
    Write-Host "Enabling Unified Audit Log and mailbox audit logs for $($thisCustomer.DisplayName)."
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
    Set-OrganizationConfig -AuditDisabled $false
}

function disconnectExchangeOnline {
    param (
        $thisCustomer
    )
    
    Write-Host "Disconnecting from $($thisCustomer.DisplayName)"
    Disconnect-ExchangeOnline -Confirm:$false
}


foreach ($customer in $customers) {
    connectExchangeOnline $customer
    enableAdminAuditLog $customer
    disconnectExchangeOnline $customer
    
    Write-Host "Sleeping 5 seconds before moving on to next tenant. `n`n"
    Start-Sleep -Seconds 5
}

Exit 0