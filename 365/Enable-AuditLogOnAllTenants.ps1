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
    Write-Host "Setting audit age limit for mailboxes to 365 days."
    $mailboxes = Get-Mailbox -ResultSize Unlimited
    $mailboxes | Set-Mailbox -AuditEnabled $true -AuditLogAgeLimit 365 -DefaultAuditSet Admin,Delegate,Owner
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
    enableAdminAuitLog $customer
    disconnectExchangeOnline $customer
    
    Write-Host "Sleeping 5 seconds before moving on to next tenant. `n`n"
    Start-Sleep -Seconds 5
}

