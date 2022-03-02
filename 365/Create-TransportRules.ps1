$allowedCharsets = @('UTF-8','US-ASCII','ISO-8859-1')
$blockedCharsetWords = @('big5','euc','gb','iso','koi','ks','ns','sen','shift','windows')


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

function disconnectExchangeOnline {
    param (
        $thisCustomer
    )
    
    Write-Host "Disconnecting from $($thisCustomer.DisplayName)"
    Disconnect-ExchangeOnline -Confirm:$false
}

function blockAbnormalCharsets {
    New-TransportRule -Name "Block Abnormal Charsets" -ContentCharacterSetContainsWords $blockedCharsetWords -ExceptIfContentCharacterSetContainsWords $allowedCharsets -Quarantine $true -Priority 0 
}



foreach ($customer in $customers) {
    connectExchangeOnline $customer
    blockAbnormalCharsets $customer
    disconnectExchangeOnline $customer
    
    Write-Host "Sleeping 5 seconds before moving on to next tenant. `n`n"
    Start-Sleep -Seconds 5
}