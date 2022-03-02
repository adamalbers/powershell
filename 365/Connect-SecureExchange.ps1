$secretsPath = '.secrets.json.secure'
$keybasePath = '/usr/local/bin/keybase'
$secrets = (& $keybasePath decrypt -i $secretsPath) | ConvertFrom-Json

$ApplicationId         = $($secrets.SecureApp.ApplicationId)
$ApplicationSecret     = $($secrets.Secureapp.ApplicationSecret) | Convertto-SecureString -AsPlainText -Force
$TenantID              = $($secrets.SecureApp.TenantId)
$RefreshToken          = $($secrets.SecureApp.RefreshToken)
$ExchangeRefreshToken  = $($secrets.SecureApp.ExchangeRefreshToken)
$upn                   = $($secrets.SecureApp.UPN)
$credential = New-Object System.Management.Automation.PSCredential($ApplicationId, $ApplicationSecret)
 
$aadGraphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal -Tenant $tenantID
$graphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal -Tenant $tenantID
 
Connect-MsolService -AdGraphAccessToken $($aadGraphToken.AccessToken) -MsGraphAccessToken $($graphToken.AccessToken)
$customers = Get-MsolPartnerContract -All

foreach($customer in $customers){
    $token = New-PartnerAccessToken -ApplicationId 'a0c73c16-a7e3-4564-9a95-2bdf47383716' -RefreshToken $ExchangeRefreshToken -Scopes 'https://outlook.office365.com/.default' -Tenant $($customer.TenantId)
    $tokenValue = ConvertTo-SecureString "Bearer $($token.AccessToken)" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($upn, $tokenValue)
    $customerId = $($customer.DefaultDomainName)
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell-liveid?DelegatedOrg=$($customerId)&BasicAuthToOAuthConversion=true" -Credential $credential -Authentication Basic -AllowRedirection
    Import-PSSession $session
    #From here you can enter your own commands
    Get-Mailbox -ResultSize 1000 | Set-Mailbox -DefaultAuditSet Admin,Delegate,Owner
    # End of Commands
    Remove-PSSession $session
}