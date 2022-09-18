# This script is kind of janky. Haven't worked on it in a long time.
# Might be pretty janky or just not work at all.
Param( 
    $configName = 'comet'
)


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
$config = Import-Config $configName

$server = $($config.server)
$username = $($config.username)
$password = $($config.password)

$endDate = (Get-Date -UFormat %s)
$startDate = $endDate - 86400


$urlBase = "https://$server/api/v1/admin"
$headers = @{
    'Content-Type'    = 'application/x-www-form-urlencoded; charset=UTF-8'
    'Accept'          = 'application/json, text/javascript, */*; q=0.01'
    'Accept-Language' = 'en-US'
}

function getSessionKey {
    $url = "$urlBase/account/session-start"
    $body = "Username=$username&AuthType=Password&Password=$password"
    $response = Invoke-RestMethod -Method POST -Body $body -Headers $headers -Uri $url
    return $($response.SessionKey)    
}

function logOut {
    $url = "$urlBase/account/session-revoke"
    $body = "Username=$username&AuthType=SessionKey&SessionKey=$sessionKey"
    $response = Invoke-RestMethod -Method POST -Body $body -Headers $headers -Uri $url
    return $response
}
function listUsers {
    $url = "$urlBase/list-users"
    $body = "Username=$username&AuthType=SessionKey&SessionKey=$sessionKey"
    $response = Invoke-RestMethod -Method POST -Body $body -Headers $headers -Uri $url
    return $response
}


$sessionKey = getSessionKey
$users = listUsers


logOut

Exit 0