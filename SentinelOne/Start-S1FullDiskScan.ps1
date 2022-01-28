# The URL will change based on your account.
# View the API docs by clicking the ? in the top right of the S1 web console.
$apiURL = 'https://subdomain.sentinelone.net/web/api/v2.1/agents/actions/initiate-scan'

# S1 tokens are only good for six months so you will need to update this
$apiToken = 'SuperLongSuperSecretAPIToken'

$headers = @{
    "Authorization" = "apitoken $apiToken"
}

$body = @"
{
    "filter": {
        "groupIds": [
          "11111111111111"
        ]
        },
      "data": {}
}
"@

$response = Invoke-RestMethod -Uri "$apiURL" -Method POST -Body $body -ContentType 'application/json' -Headers $headers

Write-Output $response.data